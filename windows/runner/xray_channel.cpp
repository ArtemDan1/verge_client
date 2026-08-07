#include "xray_channel.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "child_process.h"
#include "platform_task_runner.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

ChildProcess* g_xray = nullptr;
std::unique_ptr<flutter::EventSink<EncodableValue>> g_sink;

void EmitLog(const std::string& line) {
  if (!g_sink) return;
  g_sink->Success(EncodableValue(EncodableMap{
      {EncodableValue("type"), EncodableValue("log")},
      {EncodableValue("line"), EncodableValue(line)},
  }));
}

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

void HandleStart(const EncodableMap& args,
                 std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* cfg_val = Find(args, "config");
  if (cfg_val == nullptr) {
    result->Error("ARG", "bad args");
    return;
  }
  std::string cfg = std::get<std::string>(*cfg_val);

  std::wstring path = ChildProcess::WriteTempConfig(cfg, L"xray-config.json");
  if (path.empty()) {
    result->Error("START", "не удалось записать конфиг");
    return;
  }
  // macOS запускает "run", "-config", <путь> — сохраняем те же аргументы.
  std::string err = g_xray->Start(L"xray.exe", L"run -config \"" + path + L"\"");
  if (!err.empty()) {
    g_xray->Stop();
    result->Error("START", err);
    return;
  }
  result->Success();
}

}  // namespace

void RegisterXrayChannel(flutter::FlutterEngine* engine) {
  g_xray = new ChildProcess();

  auto events = std::make_unique<flutter::EventChannel<EncodableValue>>(
      engine->messenger(), "singbox/xray/events",
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
  events.release();

  // Колбэки приходят из фоновых потоков ChildProcess — движок Flutter трогаем
  // только с platform thread.
  g_xray->SetOnLog([](const std::string& line) {
    PlatformTaskRunner::Post([line]() { EmitLog(line); });
  });
  g_xray->SetOnCrash([](const std::string& reason) {
    PlatformTaskRunner::Post(
        [reason]() { EmitLog("xray crashed: " + reason + "\n"); });
  });

  auto method = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "singbox/xray",
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
      g_xray->Stop();
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
  method.release();
}
