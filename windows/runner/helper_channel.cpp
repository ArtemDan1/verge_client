#include "helper_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

void RegisterHelperChannel(flutter::FlutterEngine* engine) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "singbox/helper",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "status") {
      result->Success(flutter::EncodableValue("notRegistered"));
    } else {
      result->NotImplemented();
    }
  });
  channel.release();
}
