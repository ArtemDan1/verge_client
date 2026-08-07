#include "tun_channel.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <atomic>
#include <cstdint>
#include <memory>
#include <sstream>
#include <string>
#include <thread>

#include "platform_task_runner.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::unique_ptr<flutter::EventSink<EncodableValue>> g_sink;
std::atomic<bool> g_polling{false};

// Поток опроса живёт своей жизнью и никем не джойнится.
//
// Джойнить его нельзя: он спит по две секунды и делает пайп-вызовы с таймаутом
// до трёх секунд, так что join с platform thread заморозил бы интерфейс на всё
// это время. Синхронизация вместо join — поколение: перед стартом нового опроса
// счётчик увеличивается, и старый поток, увидев чужое поколение, молча выходит.
std::atomic<uint64_t> g_poll_generation{0};

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

void EmitLog(const std::string& line) {
  if (!g_sink) return;
  g_sink->Success(EncodableValue(EncodableMap{
      {EncodableValue("type"), EncodableValue("log")},
      {EncodableValue("line"), EncodableValue(line)},
  }));
}

void EmitStatus(const std::string& value) {
  if (!g_sink) return;
  g_sink->Success(EncodableValue(EncodableMap{
      {EncodableValue("type"), EncodableValue("status")},
      {EncodableValue("value"), EncodableValue(value)},
  }));
}

// Останавливает текущий опрос, не дожидаясь его потока, и возвращает номер
// поколения для нового. Вызывать можно с любого потока.
uint64_t StopPolling() {
  g_polling = false;
  return ++g_poll_generation;
}

// Опрос раз в две секунды: логи и статус. Останавливается сам, если туннель
// упал, служба недоступна, его остановили извне либо стартовал более новый
// опрос.
void PollLoop(uint64_t generation) {
  auto alive = [generation]() {
    return g_polling && g_poll_generation == generation;
  };
  while (alive()) {
    ::Sleep(2000);
    if (!alive()) return;

    std::string logs;
    bool ok = false;
    bool reachable = VergePipeCall(verge::Cmd::kLogs, "", &logs, &ok);
    if (reachable && ok && !logs.empty()) {
      std::istringstream stream(logs);
      std::string line;
      while (std::getline(stream, line)) {
        if (line.empty()) continue;
        PlatformTaskRunner::Post([line]() { EmitLog(line); });
      }
    }
    if (!alive()) return;

    std::string status;
    reachable = VergePipeCall(verge::Cmd::kStatus, "", &status, &ok);
    bool failed = !reachable || !ok || status.rfind("stopped", 0) == 0;
    if (!failed) continue;
    if (!alive()) return;

    std::string reason;
    if (!reachable) {
      reason = "служба VergeTunnel недоступна";
    } else {
      // "stopped:<причина>" — служебный префикс пользователю не нужен.
      const std::string prefix = "stopped:";
      reason = status.rfind(prefix, 0) == 0 ? status.substr(prefix.size())
                                            : status;
      if (reason.empty()) reason = "туннель остановлен";
    }
    g_polling = false;
    PlatformTaskRunner::Post([reason]() {
      EmitLog(reason + "\n");
      EmitStatus("error");
    });
    return;
  }
}

void HandleStart(const EncodableMap& args,
                 std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* cfg_val = Find(args, "config");
  if (cfg_val == nullptr) {
    result->Error("ARG", "bad args");
    return;
  }
  std::string cfg = std::get<std::string>(*cfg_val);
  // "service" принимается, но игнорируется — на Windows сетевых сервисов нет.

  std::shared_ptr<flutter::MethodResult<EncodableValue>> shared =
      std::move(result);
  std::thread([cfg, shared]() {
    std::string reply;
    bool ok = false;
    bool reachable = VergePipeCall(verge::Cmd::kStart, cfg, &reply, &ok);
    PlatformTaskRunner::Post([shared, reachable, ok, reply]() {
      if (!reachable) {
        shared->Error("PIPE", "служба VergeTunnel недоступна");
        return;
      }
      if (!ok) {
        shared->Error("START", reply);
        return;
      }
      shared->Success();
      EmitStatus("connected");
      uint64_t generation = StopPolling();
      g_polling = true;
      std::thread(PollLoop, generation).detach();
    });
  }).detach();
}

void HandleStop(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::shared_ptr<flutter::MethodResult<EncodableValue>> shared =
      std::move(result);
  StopPolling();
  std::thread([shared]() {
    std::string reply;
    bool ok = false;
    VergePipeCall(verge::Cmd::kStop, "", &reply, &ok);
    PlatformTaskRunner::Post([shared]() {
      shared->Success();
      EmitStatus("disconnected");
    });
  }).detach();
}

}  // namespace

bool VergePipeCall(verge::Cmd cmd, const std::string& payload,
                   std::string* reply, bool* ok) {
  HANDLE pipe = ::CreateFileW(verge::kPipeName, GENERIC_READ | GENERIC_WRITE, 0,
                              nullptr, OPEN_EXISTING, 0, nullptr);
  if (pipe == INVALID_HANDLE_VALUE) {
    // Все экземпляры заняты — ждём освобождения, но недолго: UI не должен
    // висеть, если служба зависла.
    if (::GetLastError() != ERROR_PIPE_BUSY) return false;
    if (!::WaitNamedPipeW(verge::kPipeName, 3000)) return false;
    pipe = ::CreateFileW(verge::kPipeName, GENERIC_READ | GENERIC_WRITE, 0,
                         nullptr, OPEN_EXISTING, 0, nullptr);
    if (pipe == INVALID_HANDLE_VALUE) return false;
  }
  bool sent = verge::WriteFrame(pipe, static_cast<uint8_t>(cmd), payload);
  uint8_t tag = 0;
  bool got = sent && verge::ReadFrame(pipe, &tag, reply);
  ::CloseHandle(pipe);
  if (!got) return false;
  *ok = static_cast<verge::Rep>(tag) == verge::Rep::kOk;
  return true;
}

void RegisterTunChannel(flutter::FlutterEngine* engine) {
  auto events = std::make_unique<flutter::EventChannel<EncodableValue>>(
      engine->messenger(), "singbox/tun/events",
      &flutter::StandardMethodCodec::GetInstance());
  events->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [](const EncodableValue*,
             std::unique_ptr<flutter::EventSink<EncodableValue>>&& sink)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            g_sink = std::move(sink);
            return nullptr;
          },
          [](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            g_sink.reset();
            return nullptr;
          }));
  events.release();  // канал живёт до конца процесса

  auto method = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "singbox/tun",
      &flutter::StandardMethodCodec::GetInstance());
  method->SetMethodCallHandler([](const auto& call, auto result) {
    const std::string& name = call.method_name();
    if (name == "start") {
      const auto* args = std::get_if<EncodableMap>(call.arguments());
      if (args == nullptr) {
        result->Error("ARG", "bad args");
        return;
      }
      HandleStart(*args, std::move(result));
    } else if (name == "stop") {
      HandleStop(std::move(result));
    } else {
      result->NotImplemented();
    }
  });
  method.release();
}
