#include "system_proxy.h"

#include <windows.h>
#include <wininet.h>

#include <string>

namespace {

constexpr wchar_t kKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";
// Локальные адреса мимо прокси: иначе Clash API на 127.0.0.1 пойдёт через
// sing-box, а тот ещё не готов их обслуживать.
constexpr wchar_t kBypass[] = L"localhost;127.*;10.*;172.16.*;192.168.*;<local>";

bool enabled_by_us = false;

bool SetDword(const wchar_t* name, DWORD value) {
  HKEY key;
  if (::RegOpenKeyExW(HKEY_CURRENT_USER, kKey, 0, KEY_SET_VALUE, &key) !=
      ERROR_SUCCESS) {
    return false;
  }
  LONG rc = ::RegSetValueExW(key, name, 0, REG_DWORD,
                             reinterpret_cast<const BYTE*>(&value),
                             sizeof(value));
  ::RegCloseKey(key);
  return rc == ERROR_SUCCESS;
}

bool SetString(const wchar_t* name, const std::wstring& value) {
  HKEY key;
  if (::RegOpenKeyExW(HKEY_CURRENT_USER, kKey, 0, KEY_SET_VALUE, &key) !=
      ERROR_SUCCESS) {
    return false;
  }
  LONG rc = ::RegSetValueExW(
      key, name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  ::RegCloseKey(key);
  return rc == ERROR_SUCCESS;
}

std::wstring GetString(const wchar_t* name) {
  HKEY key;
  if (::RegOpenKeyExW(HKEY_CURRENT_USER, kKey, 0, KEY_QUERY_VALUE, &key) !=
      ERROR_SUCCESS) {
    return L"";
  }
  wchar_t buf[512] = {};
  DWORD size = sizeof(buf);
  DWORD type = 0;
  LONG rc = ::RegQueryValueExW(key, name, nullptr, &type,
                               reinterpret_cast<BYTE*>(buf), &size);
  ::RegCloseKey(key);
  if (rc != ERROR_SUCCESS || type != REG_SZ) return L"";
  return std::wstring(buf);
}

// Без этого уже запущенные приложения продолжают использовать старые настройки.
void Notify() {
  ::InternetSetOptionW(nullptr, INTERNET_OPTION_SETTINGS_CHANGED, nullptr, 0);
  ::InternetSetOptionW(nullptr, INTERNET_OPTION_REFRESH, nullptr, 0);
}

}  // namespace

bool SystemProxy::Enable(int port) {
  std::wstring server = L"127.0.0.1:" + std::to_wstring(port);
  if (!SetString(L"ProxyServer", server)) return false;
  if (!SetString(L"ProxyOverride", kBypass)) return false;
  if (!SetDword(L"ProxyEnable", 1)) return false;
  enabled_by_us = true;
  Notify();
  return true;
}

void SystemProxy::DisableAll() {
  if (!enabled_by_us) return;
  SetDword(L"ProxyEnable", 0);
  enabled_by_us = false;
  Notify();
}

void SystemProxy::ClearIfOrphaned() {
  std::wstring server = GetString(L"ProxyServer");
  if (server.rfind(L"127.0.0.1:", 0) != 0) return;
  SetDword(L"ProxyEnable", 0);
  Notify();
}
