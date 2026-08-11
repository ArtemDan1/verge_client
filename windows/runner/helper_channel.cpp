#include "helper_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <thread>

#include "platform_task_runner.h"
#include "tun_channel.h"

void RegisterHelperChannel(flutter::FlutterEngine* engine) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "singbox/helper",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "status") {
      std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> shared =
          std::move(result);
      std::thread([shared]() {
        std::string reply;
        bool ok = false;
        // Служба не установлена или не запущена → пайпа нет → notRegistered.
        // Ровно как ping по XPC на macOS: достучались — значит enabled.
        bool reachable = VergePipeCall(verge::Cmd::kVersion, "", &reply, &ok);
        PlatformTaskRunner::Post([shared, reachable]() {
          shared->Success(flutter::EncodableValue(
              reachable ? "enabled" : "notRegistered"));
        });
      }).detach();
      return;
    }
    result->NotImplemented();
  });
  channel.release();
}
