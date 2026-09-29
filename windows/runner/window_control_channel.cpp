#include "window_control_channel.h"

#include <flutter/standard_method_codec.h>

#include "flutter_window.h"

namespace {

double GetDouble(const flutter::EncodableMap& args, const char* key,
                 double fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return fallback;
  if (const auto* d = std::get_if<double>(&it->second)) return *d;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
  return fallback;
}

bool GetBool(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return false;
  const auto* b = std::get_if<bool>(&it->second);
  return b != nullptr && *b;
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateWindowControlChannel(flutter::FlutterEngine* engine,
                           FlutterWindow* window) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "window/control",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([window](const auto& call, auto result) {
    static const flutter::EncodableMap kEmpty;
    const auto* map = std::get_if<flutter::EncodableMap>(call.arguments());
    const flutter::EncodableMap& args = map != nullptr ? *map : kEmpty;
    const std::string& method = call.method_name();
    if (method == "show") {
      window->ShowMain();
    } else if (method == "showPopover") {
      window->ShowPopover(GetDouble(args, "width", 340),
                          GetDouble(args, "height", 420));
    } else if (method == "hidePopover") {
      window->ExitPopover(GetBool(args, "openMain"), /*notify=*/false);
    } else {
      result->NotImplemented();
      return;
    }
    result->Success();
  });
  return channel;
}
