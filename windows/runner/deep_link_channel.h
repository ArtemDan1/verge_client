#ifndef RUNNER_DEEP_LINK_CHANNEL_H_
#define RUNNER_DEEP_LINK_CHANNEL_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

#include <string>

// Канал app/deeplink — доставка `verge://` в Flutter.
//
// На macOS схему приносит Apple Event. На Windows система запускает НОВЫЙ
// процесс с URL в аргументах, поэтому нужен single instance: второй экземпляр
// пересылает ссылку первому через WM_COPYDATA и выходит.

constexpr UINT kDeepLinkCopyDataId = 0x5645;  // 'VE'

// true — мы первый экземпляр. false — ссылка передана первому, надо выйти.
bool ClaimSingleInstance(const std::wstring& link);

void RegisterDeepLinkChannel(flutter::FlutterEngine* engine);

// Ссылка, пришедшая до готовности Flutter, буферизуется и отдаётся по
// getInitialLink — как pendingLink на macOS.
void DeliverDeepLink(const std::string& url);

#endif  // RUNNER_DEEP_LINK_CHANNEL_H_
