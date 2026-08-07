#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "system_proxy.h"
#include "bypass_ping_channel.h"
#include "deep_link_channel.h"
#include "helper_channel.h"
#include "platform_task_runner.h"
#include "test_channels.h"
#include "tunnel_channel.h"
#include "window_control_channel.h"
#include "xray_channel.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  // До регистрации каналов: их фоновые потоки возвращают результаты через него.
  PlatformTaskRunner::Init();
  RegisterTunnelChannel(flutter_controller_->engine());
  RegisterXrayChannel(flutter_controller_->engine());
  RegisterTestChannels(flutter_controller_->engine());
  RegisterHelperChannel(flutter_controller_->engine());
  RegisterWindowControlChannel(flutter_controller_->engine(), GetHandle());
  RegisterDeepLinkChannel(flutter_controller_->engine());
  RegisterBypassPingChannel(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_ENDSESSION:
      // Windows выключается/пользователь выходит: снять прокси сейчас, иначе
      // он останется в реестре и следующий сеанс начнётся без интернета.
      SystemProxy::DisableAll();
      break;
    case WM_CLOSE:
      // Крестик прячет окно в трей, а не завершает приложение. Выход — только
      // через пункт меню трея: он на стороне Dart отключает туннель и зовёт
      // exit(0), минуя цикл сообщений, поэтому уборка обязана случиться там.
      ::ShowWindow(hwnd, SW_HIDE);
      return 0;
    case WM_COPYDATA: {
      auto* data = reinterpret_cast<COPYDATASTRUCT*>(lparam);
      if (data != nullptr && data->dwData == kDeepLinkCopyDataId &&
          data->lpData != nullptr) {
        DeliverDeepLink(std::string(static_cast<const char*>(data->lpData)));
        ::ShowWindow(hwnd, SW_SHOW);
        ::SetForegroundWindow(hwnd);
      }
      return TRUE;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
