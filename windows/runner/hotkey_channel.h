#ifndef RUNNER_HOTKEY_CHANNEL_H_
#define RUNNER_HOTKEY_CHANNEL_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// Канал verge/hotkey — глобальная горячая клавиша «подключить/отключить»:
//   register{key, ctrl, alt, shift, meta} → bool — назначить вместо прежней
//                                           (false — сочетание занято);
//   unregister                            — снять.
// Обратно в Dart идёт pressed. Регистрация — RegisterHotKey на главном окне,
// нажатие приходит ему же как WM_HOTKEY (см. FlutterWindow::MessageHandler).
class HotkeyChannel {
 public:
  HotkeyChannel(flutter::FlutterEngine* engine, HWND window);
  ~HotkeyChannel();

  HotkeyChannel(const HotkeyChannel&) = delete;
  HotkeyChannel& operator=(const HotkeyChannel&) = delete;

  // Обработать WM_HOTKEY; true — это наше сочетание.
  bool HandleHotkey(WPARAM id);

 private:
  bool Register(const flutter::EncodableMap& args);
  void Unregister();

  HWND window_;
  bool registered_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_HOTKEY_CHANNEL_H_
