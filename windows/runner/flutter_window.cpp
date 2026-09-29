#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include <algorithm>
#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "system_proxy.h"
#include "bypass_ping_channel.h"
#include "deep_link_channel.h"
#include "helper_channel.h"
#include "platform_task_runner.h"
#include "test_channels.h"
#include "tun_channel.h"
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
  RegisterTunChannel(flutter_controller_->engine());
  RegisterXrayChannel(flutter_controller_->engine());
  RegisterTestChannels(flutter_controller_->engine());
  RegisterHelperChannel(flutter_controller_->engine());
  window_channel_ =
      CreateWindowControlChannel(flutter_controller_->engine(), this);
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
  window_channel_ = nullptr;
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
      if (in_popover_) {
        ExitPopover(/*show_main=*/false, /*notify=*/true);
      } else {
        ::ShowWindow(hwnd, SW_HIDE);
      }
      return 0;
    case WM_ACTIVATE:
      // Мини-окно трея закрывается, как только пользователь кликнул мимо.
      if (in_popover_ && LOWORD(wparam) == WA_INACTIVE) {
        ExitPopover(/*show_main=*/false, /*notify=*/true);
        return 0;
      }
      break;
    case WM_COPYDATA: {
      auto* data = reinterpret_cast<COPYDATASTRUCT*>(lparam);
      if (data != nullptr && data->dwData == kDeepLinkCopyDataId &&
          data->lpData != nullptr) {
        DeliverDeepLink(std::string(static_cast<const char*>(data->lpData)));
        ShowMain();
      }
      return TRUE;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::ShowMain() {
  if (in_popover_) {
    // Dart переключит интерфейс обратно на главный экран по уведомлению.
    ExitPopover(/*show_main=*/true, /*notify=*/true);
    return;
  }
  HWND hwnd = GetHandle();
  ::ShowWindow(hwnd, SW_SHOW);
  ::ShowWindow(hwnd, SW_RESTORE);
  ::SetForegroundWindow(hwnd);
}

// DWMWA_WINDOW_CORNER_PREFERENCE и его значения есть только в свежих SDK —
// числа из документации, чтобы собиралось и на старом. Windows 10 атрибут
// просто игнорирует.
static constexpr DWORD kDwmCornerPreference = 33;
static constexpr int kDwmCornerDefault = 0;
static constexpr int kDwmCornerRound = 2;

void FlutterWindow::ShowPopover(double width, double height) {
  HWND hwnd = GetHandle();
  if (!in_popover_) {
    saved_placement_.length = sizeof(WINDOWPLACEMENT);
    ::GetWindowPlacement(hwnd, &saved_placement_);
    const bool iconic = ::IsIconic(hwnd) != FALSE;
    const bool visible = ::IsWindowVisible(hwnd) != FALSE;
    was_visible_ = visible && !iconic;
    was_minimized_ = visible && iconic;
    // Прячем ДО флага: скрытие активного окна шлёт WM_ACTIVATE(WA_INACTIVE),
    // и с уже выставленным флагом мини-окно тут же закрылось бы.
    ::ShowWindow(hwnd, SW_HIDE);
    if (iconic) {
      // Свёрнутое окно остаётся свёрнутым и после SWP_SHOWWINDOW — мини-окно
      // так и не появилось бы. Разворачиваем его за пределами экрана (без
      // мелькания) и снова прячем; настоящее место задаст SetWindowPos ниже,
      // а прежнее вернёт ExitPopover из saved_placement_.
      WINDOWPLACEMENT offscreen = saved_placement_;
      offscreen.flags = 0;
      offscreen.showCmd = SW_SHOWNOACTIVATE;
      const LONG w = offscreen.rcNormalPosition.right -
                     offscreen.rcNormalPosition.left;
      const LONG h = offscreen.rcNormalPosition.bottom -
                     offscreen.rcNormalPosition.top;
      offscreen.rcNormalPosition = {-32000, -32000, -32000 + w, -32000 + h};
      ::SetWindowPlacement(hwnd, &offscreen);
      ::ShowWindow(hwnd, SW_HIDE);
    }
    // Стили — уже после разворота: у свёрнутого окна в них WS_MINIMIZE.
    saved_style_ = ::GetWindowLongPtr(hwnd, GWL_STYLE);
    saved_ex_style_ = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    in_popover_ = true;
    // Без рамки и заголовка; TOOLWINDOW — без кнопки на панели задач.
    ::SetWindowLongPtr(hwnd, GWL_STYLE,
                       (saved_style_ & ~WS_OVERLAPPEDWINDOW) | WS_POPUP);
    ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, saved_ex_style_ | WS_EX_TOOLWINDOW);
    int corner = kDwmCornerRound;
    ::DwmSetWindowAttribute(hwnd, kDwmCornerPreference, &corner,
                            sizeof(corner));
  }

  // Клик по значку только что был — курсор над ним. Прижимаемся к той
  // стороне рабочей области, где стоит панель задач.
  POINT cursor;
  ::GetCursorPos(&cursor);
  HMONITOR monitor = ::MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  ::GetMonitorInfo(monitor, &info);
  const RECT work = info.rcWork;
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const int w = static_cast<int>(width * scale);
  const int h = static_cast<int>(height * scale);
  const int margin = static_cast<int>(8 * scale);

  int x = cursor.x - w / 2;
  int y = cursor.y - h - margin;
  if (cursor.y >= work.bottom) {
    y = work.bottom - h - margin;  // панель задач снизу
  } else if (cursor.y < work.top) {
    y = work.top + margin;  // сверху
  }
  if (cursor.x >= work.right) {
    x = work.right - w - margin;  // справа
  } else if (cursor.x < work.left) {
    x = work.left + margin;  // слева
  }
  x = std::clamp<int>(x, work.left + margin,
                      std::max<int>(work.left + margin,
                                    work.right - w - margin));
  y = std::clamp<int>(y, work.top + margin,
                      std::max<int>(work.top + margin,
                                    work.bottom - h - margin));

  ::SetWindowPos(hwnd, HWND_TOPMOST, x, y, w, h,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW);
  ::SetForegroundWindow(hwnd);
}

void FlutterWindow::ExitPopover(bool show_main, bool notify) {
  HWND hwnd = GetHandle();
  if (!in_popover_) {
    if (show_main) ShowMain();
    return;
  }
  in_popover_ = false;
  ::ShowWindow(hwnd, SW_HIDE);
  ::SetWindowLongPtr(hwnd, GWL_STYLE, saved_style_);
  ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, saved_ex_style_);
  int corner = kDwmCornerDefault;
  ::DwmSetWindowAttribute(hwnd, kDwmCornerPreference, &corner, sizeof(corner));
  ::SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_NOACTIVATE);
  WINDOWPLACEMENT placement = saved_placement_;
  // Главное окно было свёрнуто — возвращаем его на панель задач свёрнутым,
  // иначе вместе с мини-окном пропала бы и кнопка приложения.
  placement.showCmd =
      was_minimized_ && !show_main ? SW_SHOWMINNOACTIVE : SW_HIDE;
  ::SetWindowPlacement(hwnd, &placement);

  if (notify && window_channel_) {
    window_channel_->InvokeMethod("popoverDismissed", nullptr);
  }
  if (show_main) {
    ShowMain();
  } else if (was_visible_) {
    // Главное окно было открыто до мини-окна — возвращаем его, но фокус не
    // отбираем: пользователь только что кликнул в другое место.
    ::ShowWindow(hwnd, SW_SHOWNOACTIVATE);
  }
}
