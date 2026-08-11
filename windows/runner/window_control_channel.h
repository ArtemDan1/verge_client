#ifndef RUNNER_WINDOW_CONTROL_CHANNEL_H_
#define RUNNER_WINDOW_CONTROL_CHANNEL_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

// Канал window/control — показ окна из Dart (пункт «Открыть» в меню трея).
// Скрытие при закрытии крестиком делает нативный обработчик WM_CLOSE, без
// похода в Dart — как windowShouldClose на macOS.
void RegisterWindowControlChannel(flutter::FlutterEngine* engine, HWND window);

#endif  // RUNNER_WINDOW_CONTROL_CHANNEL_H_
