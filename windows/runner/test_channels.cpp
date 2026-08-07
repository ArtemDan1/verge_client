#include "test_channels.h"

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

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

// Общая обвязка для тестового канала: свой ChildProcess, свой event sink,
// события — голая строка лога (не map), как на macOS.
struct TestChannel {
  ChildProcess process;
  std::unique_ptr<flutter::EventSink<EncodableValue>> sink;

  void Emit(const std::string& line) {
    if (sink) sink->Success(EncodableValue(line));
  }
};

TestChannel* g_singbox_test = nullptr;
TestChannel* g_xray_test = nullptr;

void RegisterOne(flutter::FlutterEngine* engine, TestChannel* ch,
                 const char* method_name, const char* events_name,
                 const std::wstring& exe_name, const wchar_t* run_flag,
                 const std::wstring& config_name,
                 const std::string& crash_prefix) {
  auto events = std::make_unique<flutter::EventChannel<EncodableValue>>(
      engine->messenger(), events_name,
      &flutter::StandardMethodCodec::GetInstance());
  events->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [ch](const EncodableValue*,
               std::unique_ptr<flutter::EventSink<EncodableValue>>&& s)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            ch->sink = std::move(s);
            return nullptr;
          },
          [ch](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            ch->sink.reset();
            return nullptr;
          }));
  events.release();

  // Логи и крах приходят из фоновых потоков ChildProcess — на platform thread
  // их переносит PlatformTaskRunner. TestChannel живёт до конца процесса,
  // поэтому захват ch по указателю безопасен.
  ch->process.SetOnLog([ch](const std::string& line) {
    PlatformTaskRunner::Post([ch, line]() { ch->Emit(line); });
  });
  ch->process.SetOnCrash([ch, crash_prefix](const std::string& reason) {
    PlatformTaskRunner::Post([ch, crash_prefix, reason]() {
      ch->Emit(crash_prefix + " crashed: " + reason + "\n");
    });
  });

  auto method = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), method_name,
      &flutter::StandardMethodCodec::GetInstance());
  method->SetMethodCallHandler([ch, exe_name, run_flag, config_name](
                                   const auto& call, auto result) {
    const std::string& name = call.method_name();
    if (name == "start") {
      const auto* args = std::get_if<EncodableMap>(call.arguments());
      const auto* cfg_val = args ? Find(*args, "config") : nullptr;
      if (cfg_val == nullptr) {
        result->Error("ARG", "bad args");
        return;
      }
      std::string cfg = std::get<std::string>(*cfg_val);
      std::wstring path = ChildProcess::WriteTempConfig(cfg, config_name);
      if (path.empty()) {
        result->Error("START", "не удалось записать конфиг");
        return;
      }
      std::wstring args_str =
          std::wstring(run_flag) + L" \"" + path + L"\"";
      std::string err = ch->process.Start(exe_name, args_str);
      if (!err.empty()) {
        ch->process.Stop();
        result->Error("START", err);
        return;
      }
      result->Success();
    } else if (name == "stop") {
      ch->process.Stop();
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
  method.release();
}

}  // namespace

void RegisterTestChannels(flutter::FlutterEngine* engine) {
  g_singbox_test = new TestChannel();
  g_xray_test = new TestChannel();

  RegisterOne(engine, g_singbox_test, "singbox/test", "singbox/test/events",
             L"sing-box-test.exe", L"run -c", L"sing-box-test-config.json",
             "sing-box-test");
  RegisterOne(engine, g_xray_test, "xray/test", "xray/test/events",
             L"xray.exe", L"run -config", L"xray-test-config.json",
             "xray-test");
}
