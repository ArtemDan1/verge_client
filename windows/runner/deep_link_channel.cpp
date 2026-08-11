#include "deep_link_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace {

constexpr wchar_t kMutexName[] = L"Global\\VergeClientSingleInstance";
constexpr wchar_t kWindowTitle[] = L"Verge";

flutter::MethodChannel<flutter::EncodableValue>* g_channel = nullptr;
std::string g_pending;

std::string Narrow(const std::wstring& s) {
  int len = ::WideCharToMultiByte(CP_UTF8, 0, s.c_str(),
                                  static_cast<int>(s.size()), nullptr, 0,
                                  nullptr, nullptr);
  std::string out(len, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, s.c_str(), static_cast<int>(s.size()),
                        out.data(), len, nullptr, nullptr);
  return out;
}

}  // namespace

bool ClaimSingleInstance(const std::wstring& link) {
  ::CreateMutexW(nullptr, TRUE, kMutexName);
  if (::GetLastError() != ERROR_ALREADY_EXISTS) {
    if (!link.empty()) g_pending = Narrow(link);
    return true;
  }
  HWND existing = ::FindWindowW(nullptr, kWindowTitle);
  if (existing != nullptr) {
    ::ShowWindow(existing, SW_SHOW);
    ::SetForegroundWindow(existing);
    if (!link.empty()) {
      std::string utf8 = Narrow(link);
      COPYDATASTRUCT data{};
      data.dwData = kDeepLinkCopyDataId;
      data.cbData = static_cast<DWORD>(utf8.size() + 1);
      data.lpData = const_cast<char*>(utf8.c_str());
      ::SendMessageW(existing, WM_COPYDATA, 0,
                     reinterpret_cast<LPARAM>(&data));
    }
  }
  return false;
}

void RegisterDeepLinkChannel(flutter::FlutterEngine* engine) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "app/deeplink",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() != "getInitialLink") {
      result->NotImplemented();
      return;
    }
    if (g_pending.empty()) {
      result->Success();
    } else {
      result->Success(flutter::EncodableValue(g_pending));
      g_pending.clear();
    }
  });
  g_channel = channel.release();
}

void DeliverDeepLink(const std::string& url) {
  if (g_channel != nullptr) {
    g_channel->InvokeMethod(
        "onLink", std::make_unique<flutter::EncodableValue>(url));
  } else {
    g_pending = url;
  }
}
