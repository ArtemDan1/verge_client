#ifndef RUNNER_XRAY_CHANNEL_H_
#define RUNNER_XRAY_CHANNEL_H_

#include <flutter/flutter_engine.h>

// Канал singbox/xray — второй движок (hysteria2, vless+xhttp).
// Зеркало macos/Runner/XrayChannel.swift.
void RegisterXrayChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_XRAY_CHANNEL_H_
