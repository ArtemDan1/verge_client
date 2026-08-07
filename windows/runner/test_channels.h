#ifndef RUNNER_TEST_CHANNELS_H_
#define RUNNER_TEST_CHANNELS_H_

#include <flutter/flutter_engine.h>

// Каналы singbox/test и xray/test — отдельные процессы для замера задержки нод.
// Боевой туннель не трогают: прокси здесь не переключается.
void RegisterTestChannels(flutter::FlutterEngine* engine);

#endif  // RUNNER_TEST_CHANNELS_H_
