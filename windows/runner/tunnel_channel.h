#ifndef RUNNER_TUNNEL_CHANNEL_H_
#define RUNNER_TUNNEL_CHANNEL_H_

#include <flutter/flutter_engine.h>

// Канал singbox/tunnel + singbox/tunnel/events: proxy-режим.
// Зеркало macos/Runner/TunnelChannel.swift.
void RegisterTunnelChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_TUNNEL_CHANNEL_H_
