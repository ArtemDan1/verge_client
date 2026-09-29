#ifndef RUNNER_WINDOW_CONTROL_CHANNEL_H_
#define RUNNER_WINDOW_CONTROL_CHANNEL_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>

#include <memory>

class FlutterWindow;

// Канал window/control:
//   show                      — показать главное окно (пункт меню трея);
//   showPopover{width,height} — мини-окно трея у значка;
//   hidePopover{openMain}     — закрыть мини-окно, при openMain — открыть
//                               главное.
// Обратно в Dart идёт popoverDismissed, когда мини-окно закрылось само
// (потеря фокуса). Скрытие при закрытии крестиком делает нативный обработчик
// WM_CLOSE, без похода в Dart — как windowShouldClose на macOS.
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateWindowControlChannel(flutter::FlutterEngine* engine,
                           FlutterWindow* window);

#endif  // RUNNER_WINDOW_CONTROL_CHANNEL_H_
