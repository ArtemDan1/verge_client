#ifndef RUNNER_BYPASS_PING_CHANNEL_H_
#define RUNNER_BYPASS_PING_CHANNEL_H_

#include <flutter/flutter_engine.h>

// Канал verge/bypass_ping — TCP-connect и QUIC-проба мимо туннеля.
//
// В TUN-режиме sing-box перехватывает системный роутинг, и обычный connect из
// Dart уходит внутрь туннеля: «пинг до ноды» мерил бы сам туннель. Обход —
// привязка сокета к физическому интерфейсу опцией IP_UNICAST_IF (аналог
// IP_BOUND_IF на macOS), которой у dart:io нет. Отсюда нативный канал.
void RegisterBypassPingChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_BYPASS_PING_CHANNEL_H_
