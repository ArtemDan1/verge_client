#include "hotkey_channel.h"

#include <flutter/standard_method_codec.h>

#include <string>

namespace {

// Идентификатор хоткея в RegisterHotKey — приложению отведён 0x0000–0xBFFF.
constexpr int kToggleHotkeyId = 0x5647;

bool GetBool(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return false;
  const auto* b = std::get_if<bool>(&it->second);
  return b != nullptr && *b;
}

// Имена клавиш из lib/app/hotkey.dart → виртуальные коды. Буквы и цифры у
// VK совпадают с ASCII и привязаны к положению клавиши, а не к раскладке.
UINT VirtualKeyFor(const std::string& key) {
  if (key.size() == 1) {
    const char c = key[0];
    if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
      return static_cast<UINT>(c);
    }
    return 0;
  }
  if (key == "Space") return VK_SPACE;
  if (key.size() >= 2 && key[0] == 'F') {
    try {
      const int n = std::stoi(key.substr(1));
      if (n >= 1 && n <= 12) return VK_F1 + (n - 1);
    } catch (...) {
    }
  }
  return 0;
}

}  // namespace

HotkeyChannel::HotkeyChannel(flutter::FlutterEngine* engine, HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "verge/hotkey",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    const std::string& method = call.method_name();
    if (method == "register") {
      static const flutter::EncodableMap kEmpty;
      const auto* map = std::get_if<flutter::EncodableMap>(call.arguments());
      result->Success(flutter::EncodableValue(Register(map ? *map : kEmpty)));
    } else if (method == "unregister") {
      Unregister();
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

HotkeyChannel::~HotkeyChannel() {
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  Unregister();
}

bool HotkeyChannel::Register(const flutter::EncodableMap& args) {
  Unregister();
  auto it = args.find(flutter::EncodableValue("key"));
  if (it == args.end()) return false;
  const auto* key = std::get_if<std::string>(&it->second);
  if (key == nullptr) return false;
  const UINT vk = VirtualKeyFor(*key);
  if (vk == 0) return false;
  // MOD_NOREPEAT: зажатое сочетание не дёргает VPN туда-обратно.
  UINT modifiers = MOD_NOREPEAT;
  if (GetBool(args, "ctrl")) modifiers |= MOD_CONTROL;
  if (GetBool(args, "alt")) modifiers |= MOD_ALT;
  if (GetBool(args, "shift")) modifiers |= MOD_SHIFT;
  if (GetBool(args, "meta")) modifiers |= MOD_WIN;
  registered_ =
      ::RegisterHotKey(window_, kToggleHotkeyId, modifiers, vk) != FALSE;
  return registered_;
}

void HotkeyChannel::Unregister() {
  if (!registered_) return;
  ::UnregisterHotKey(window_, kToggleHotkeyId);
  registered_ = false;
}

bool HotkeyChannel::HandleHotkey(WPARAM id) {
  if (static_cast<int>(id) != kToggleHotkeyId || !channel_) return false;
  channel_->InvokeMethod("pressed", nullptr);
  return true;
}
