#include "tunnel_channel.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <windows.h>

#include <memory>
#include <string>

#include "child_process.h"
#include "platform_task_runner.h"
#include "system_proxy.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

ChildProcess* g_singbox = nullptr;
std::unique_ptr<flutter::EventSink<EncodableValue>> g_sink;

void EmitLog(const std::string& line) {
  if (!g_sink) return;
  g_sink->Success(EncodableValue(EncodableMap{
      {EncodableValue("type"), EncodableValue("log")},
      {EncodableValue("line"), EncodableValue(line)},
  }));
}

void EmitStatus(const std::string& value, const std::string& message) {
  if (!g_sink) return;
  g_sink->Success(EncodableValue(EncodableMap{
      {EncodableValue("type"), EncodableValue("status")},
      {EncodableValue("value"), EncodableValue(value)},
      {EncodableValue("message"), EncodableValue(message)},
  }));
}

// "sing-box version 1.13.12" → "1.13.12"
std::string ParseSingboxVersion(const std::string& out) {
  const std::string prefix = "sing-box version ";
  size_t line_end = out.find('\n');
  std::string first = out.substr(0, line_end);
  size_t pos = first.find(prefix);
  if (pos == std::string::npos) return "unknown";
  std::string v = first.substr(pos + prefix.size());
  while (!v.empty() && (v.back() == '\r' || v.back() == ' ')) v.pop_back();
  return v.empty() ? "unknown" : v;
}

// "Xray 26.3.27 (...)" → "26.3.27" (второе слово первой строки)
std::string ParseXrayVersion(const std::string& out) {
  size_t line_end = out.find('\n');
  std::string first = out.substr(0, line_end);
  size_t sp = first.find(' ');
  if (sp == std::string::npos) return "unknown";
  size_t sp2 = first.find(' ', sp + 1);
  std::string v = first.substr(sp + 1, sp2 == std::string::npos
                                            ? std::string::npos
                                            : sp2 - sp - 1);
  while (!v.empty() && (v.back() == '\r')) v.pop_back();
  return v.empty() ? "unknown" : v;
}

std::wstring Widen(const std::string& s) {
  int len = ::MultiByteToWideChar(CP_UTF8, 0, s.c_str(),
                                  static_cast<int>(s.size()), nullptr, 0);
  std::wstring out(len, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, s.c_str(), static_cast<int>(s.size()),
                        out.data(), len);
  return out;
}

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

void HandleStart(const EncodableMap& args,
                 std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* cfg_val = Find(args, "config");
  const auto* port_val = Find(args, "port");
  if (cfg_val == nullptr || port_val == nullptr) {
    result->Error("ARG", "bad args");
    return;
  }
  std::string cfg = std::get<std::string>(*cfg_val);
  int port = std::get<int>(*port_val);

  std::wstring path = ChildProcess::WriteTempConfig(cfg, L"sing-box-config.json");
  if (path.empty()) {
    result->Error("START", "не удалось записать конфиг");
    return;
  }
  std::string err = g_singbox->Start(L"sing-box.exe", L"run -c \"" + path + L"\"");
  if (!err.empty()) {
    result->Error("START", err);
    return;
  }
  if (!SystemProxy::Enable(port)) {
    g_singbox->Stop();
    result->Error("START", "не удалось записать настройки прокси");
    return;
  }
  result->Success();
}

// Запускает скачанный инсталлятор и выходит.
//
// Выйти обязательно: инсталлятор перезаписывает exe под работающим процессом и
// перезапускает службу. Прокси снимаем до выхода — иначе он останется висеть.
void HandleInstallUpdate(
    const std::string& path,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  SystemProxy::DisableAll();
  g_singbox->Stop();

  std::wstring wpath = Widen(path);
  if (::GetFileAttributesW(wpath.c_str()) == INVALID_FILE_ATTRIBUTES) {
    result->Error("OPEN", "файл не найден: " + path);
    return;
  }
  SHELLEXECUTEINFOW info{};
  info.cbSize = sizeof(info);
  info.lpVerb = L"open";
  info.lpFile = wpath.c_str();
  // /SILENT — инсталлятор Inno Setup без интерактивных страниц.
  info.lpParameters = L"/SILENT";
  info.nShow = SW_SHOW;
  if (!::ShellExecuteExW(&info)) {
    result->Error("OPEN", "не удалось запустить инсталлятор");
    return;
  }
  result->Success();
  // Небольшая задержка, чтобы result успел уехать в Flutter до выхода.
  ::Sleep(500);
  ::PostQuitMessage(0);
}

}  // namespace

void RegisterTunnelChannel(flutter::FlutterEngine* engine) {
  // Осиротевший прокси от прошлого запуска — до всего остального.
  SystemProxy::ClearIfOrphaned();

  g_singbox = new ChildProcess();

  auto events = std::make_unique<flutter::EventChannel<EncodableValue>>(
      engine->messenger(), "singbox/tunnel/events",
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

  // Оба колбэка приходят из фоновых потоков ChildProcess, а движок Flutter
  // терпит обращения только с platform thread — отсюда Post.
  g_singbox->SetOnLog([](const std::string& line) {
    PlatformTaskRunner::Post([line]() { EmitLog(line); });
  });
  // Процесс упал сам: снимаем прокси, иначе останется висячий прокси и
  // ERR_PROXY_CONNECTION_FAILED во всех браузерах.
  g_singbox->SetOnCrash([](const std::string& reason) {
    PlatformTaskRunner::Post([reason]() {
      SystemProxy::DisableAll();
      EmitLog("sing-box crashed: " + reason + "\n");
      EmitStatus("error", reason);
    });
  });

  auto method = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "singbox/tunnel",
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
      SystemProxy::DisableAll();
      g_singbox->Stop();
      result->Success();
    } else if (name == "singboxVersion") {
      result->Success(EncodableValue(ParseSingboxVersion(
          ChildProcess::RunAndCapture(L"sing-box.exe", L"version"))));
    } else if (name == "xrayVersion") {
      result->Success(EncodableValue(ParseXrayVersion(
          ChildProcess::RunAndCapture(L"xray.exe", L"version"))));
    } else if (name == "listNetworkServices") {
      // На Windows прокси общесистемный, выбирать нечего — UI прячет секцию.
      result->Success(EncodableValue(flutter::EncodableList{}));
    } else if (name == "defaultService") {
      result->Success();
    } else if (name == "installUpdate") {
      const auto* path = std::get_if<std::string>(call.arguments());
      if (path == nullptr) {
        result->Error("ARG", "no path");
        return;
      }
      HandleInstallUpdate(*path, std::move(result));
    } else {
      result->NotImplemented();
    }
  });
  method.release();
}
