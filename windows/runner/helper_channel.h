#ifndef RUNNER_HELPER_CHANNEL_H_
#define RUNNER_HELPER_CHANNEL_H_

#include <flutter/flutter_engine.h>

// Канал singbox/helper — доступность привилегированной службы.
// Пока служба не реализована, всегда "notRegistered": UI покажет TUN как
// недоступный ровно так же, как на macOS без установленного демона.
void RegisterHelperChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_HELPER_CHANNEL_H_
