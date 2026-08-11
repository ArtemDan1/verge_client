#include "window_control_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

void RegisterWindowControlChannel(flutter::FlutterEngine* engine, HWND window) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "window/control",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([window](const auto& call, auto result) {
    if (call.method_name() != "show") {
      result->NotImplemented();
      return;
    }
    if (!::IsWindow(window)) {
      result->Error("NO_WINDOW", "Главное окно не найдено");
      return;
    }
    ::ShowWindow(window, SW_SHOW);
    ::ShowWindow(window, SW_RESTORE);
    ::SetForegroundWindow(window);
    result->Success();
  });
  channel.release();
}
