#ifndef RUNNER_TUN_CHANNEL_H_
#define RUNNER_TUN_CHANNEL_H_

#include <flutter/flutter_engine.h>

#include <string>

#include "../service/pipe_protocol.h"

// Канал singbox/tun + singbox/tun/events. Проксирует start/stop
// привилегированной службе VergeTunnel через named pipe.
// Зеркало macos/Runner/TunChannel.swift, где ту же роль играл XPC.
void RegisterTunChannel(flutter::FlutterEngine* engine);

// Одна команда службе: подключиться, отправить, прочитать ответ, закрыть.
// Возвращает false, если служба недоступна (не установлена, не запущена,
// не отвечает). Вынесена сюда, чтобы её мог использовать helper_channel.cpp
// для пинга службы без дублирования.
bool VergePipeCall(verge::Cmd cmd, const std::string& payload,
                   std::string* reply, bool* ok);

#endif  // RUNNER_TUN_CHANNEL_H_
