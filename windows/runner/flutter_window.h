#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
//
// Кроме главного окна умеет временно становиться мини-окном трея: без рамки,
// поверх всех, у значка в области уведомлений. Второго окна нет — Flutter
// рисует в то же окно компактный интерфейс (см. lib/ui/tray_popover.dart).
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  // Показать главное окно; из режима мини-окна сначала выходит.
  void ShowMain();

  // Превратить окно в мини-окно трея размером |width|×|height| логических
  // пикселей и показать у курсора (клик по значку трея только что был).
  void ShowPopover(double width, double height);

  // Вернуть окну прежний вид. |show_main| — сразу показать главное окно,
  // |notify| — сообщить Dart, что мини-окно закрылось не по его команде.
  void ExitPopover(bool show_main, bool notify);

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Канал window/control: команды из Dart и уведомление о закрытии мини-окна.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;

  // Состояние главного окна на время мини-окна.
  bool in_popover_ = false;
  bool was_visible_ = false;
  LONG_PTR saved_style_ = 0;
  LONG_PTR saved_ex_style_ = 0;
  WINDOWPLACEMENT saved_placement_{};
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
