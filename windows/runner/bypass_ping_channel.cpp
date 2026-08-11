// Winsock — самым первым включением в файле, до любых заголовков Flutter.
// windows.h тянет за собой winsock.h версии 1.1, а тот конфликтует с
// winsock2.h: sockaddr объявляется дважды, AF_IPX и половина констант
// переопределяются. Заголовки Flutter включают windows.h, поэтому порядок
// здесь значимый, а не косметический. iphlpapi.h тоже обязан идти после
// winsock2.h — он опирается на его типы.
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>

#include "bypass_ping_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <climits>
#include <cwctype>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "platform_task_runner.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

// true, если в строке есть подстрока (обе сравниваются без учёта регистра).
bool ContainsNoCaseW(const wchar_t* haystack, const wchar_t* needle) {
  if (haystack == nullptr) return false;
  std::wstring hay(haystack);
  for (auto& c : hay) c = static_cast<wchar_t>(::towlower(c));
  return hay.find(needle) != std::wstring::npos;
}

// Виртуальный ли это адаптер туннеля.
//
// По одному лишь IfType их не отсечь: wintun-адаптер, который поднимает
// sing-box, докладывается как IF_TYPE_PROPVIRTUAL, а иногда и как обычный
// Ethernet — IF_TYPE_TUNNEL он не выставляет. Поэтому смотрим ещё и на имена:
// драйвер описывает себя «Wintun Userspace Tunnel», а адаптеру sing-box даёт
// имя своего inbound'а.
bool IsTunnelAdapter(const IP_ADAPTER_ADDRESSES* a) {
  if (a->IfType == IF_TYPE_TUNNEL || a->IfType == IF_TYPE_PROP_VIRTUAL) {
    return true;
  }
  return ContainsNoCaseW(a->Description, L"wintun") ||
         ContainsNoCaseW(a->Description, L"tap-windows") ||
         ContainsNoCaseW(a->FriendlyName, L"wintun") ||
         ContainsNoCaseW(a->FriendlyName, L"sing-box") ||
         ContainsNoCaseW(a->FriendlyName, L"verge");
}

// Индекс физического интерфейса с активным IPv4-адресом.
//
// Туннельные адаптеры пропускаем — ради обхода именно их всё и затевается.
// Отбор строго по «не туннель», а не по метрике саму по себе: в TUN-режиме
// именно туннельный адаптер получает наименьшую метрику (так он и перехватывает
// трафик), и выбор по метрике вернул бы его — замер тогда показывал бы задержку
// до входа в туннель, те самые 2-3 мс вместо реального пинга до сервера.
//
// 0 означает «не нашли»: тогда сокет никуда не привязываем и замер идёт обычным
// путём (лучше не совсем честное число, чем никакого).
DWORD PhysicalInterfaceIndex() {
  ULONG size = 15000;
  std::vector<char> buf(size);
  auto* addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buf.data());
  ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                GAA_FLAG_SKIP_DNS_SERVER;
  ULONG rc = ::GetAdaptersAddresses(AF_INET, flags, nullptr, addrs, &size);
  if (rc == ERROR_BUFFER_OVERFLOW) {
    // GetAdaptersAddresses вернул нужный размер в size — пробуем ещё раз.
    buf.assign(size, 0);
    addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buf.data());
    rc = ::GetAdaptersAddresses(AF_INET, flags, nullptr, addrs, &size);
  }
  if (rc != NO_ERROR) return 0;

  DWORD best_index = 0;
  ULONG best_metric = ULONG_MAX;
  for (auto* a = addrs; a != nullptr; a = a->Next) {
    if (a->OperStatus != IfOperStatusUp) continue;
    if (a->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
    if (IsTunnelAdapter(a)) continue;
    if (a->FirstUnicastAddress == nullptr) continue;
    if (a->Ipv4Metric < best_metric) {
      best_metric = a->Ipv4Metric;
      best_index = a->IfIndex;
    }
  }
  return best_index;
}

void BindToInterface(SOCKET s, int family, DWORD if_index) {
  if (if_index == 0) return;
  if (family == AF_INET6) {
    ::setsockopt(s, IPPROTO_IPV6, IPV6_UNICAST_IF,
                 reinterpret_cast<const char*>(&if_index), sizeof(if_index));
  } else {
    // Для IPv4 значение задаётся в сетевом порядке байт — задокументированная
    // асимметрия IP_UNICAST_IF, без неё привязка молча не работает.
    DWORD be = ::htonl(if_index);
    ::setsockopt(s, IPPROTO_IP, IP_UNICAST_IF,
                 reinterpret_cast<const char*>(&be), sizeof(be));
  }
}

// Пакет с зарезервированной версией QUIC (0x0a0a0a0a) и случайными connection
// id, добитый до 1200 байт: датаграммы меньшего размера сервер вправе
// отбросить.
std::vector<char> QuicVersionNegotiationProbe() {
  std::vector<char> packet(1200, 0);
  packet[0] = static_cast<char>(0xC0);  // long header, fixed bit
  packet[1] = 0x0A;
  packet[2] = 0x0A;
  packet[3] = 0x0A;
  packet[4] = 0x0A;
  size_t i = 5;
  for (int cid = 0; cid < 2; cid++) {
    packet[i++] = 8;  // длина connection id
    for (int b = 0; b < 8; b++) {
      packet[i++] = static_cast<char>(::rand() & 0xFF);
    }
  }
  return packet;
}

std::optional<int> ConnectMs(addrinfo* info, DWORD if_index, int timeout_ms) {
  SOCKET s = ::socket(info->ai_family, info->ai_socktype, info->ai_protocol);
  if (s == INVALID_SOCKET) return std::nullopt;
  BindToInterface(s, info->ai_family, if_index);

  u_long mode = 1;
  ::ioctlsocket(s, FIONBIO, &mode);

  LARGE_INTEGER freq, start, end;
  ::QueryPerformanceFrequency(&freq);
  ::QueryPerformanceCounter(&start);

  int rc = ::connect(s, info->ai_addr, static_cast<int>(info->ai_addrlen));
  if (rc != 0 && ::WSAGetLastError() != WSAEWOULDBLOCK) {
    ::closesocket(s);
    return std::nullopt;
  }
  fd_set write_set;
  FD_ZERO(&write_set);
  FD_SET(s, &write_set);
  timeval tv{timeout_ms / 1000, (timeout_ms % 1000) * 1000};
  int ready = ::select(0, nullptr, &write_set, nullptr, &tv);
  if (ready <= 0) {
    ::closesocket(s);
    return std::nullopt;
  }
  int so_error = 0;
  int len = sizeof(so_error);
  if (::getsockopt(s, SOL_SOCKET, SO_ERROR,
                   reinterpret_cast<char*>(&so_error), &len) != 0 ||
      so_error != 0) {
    ::closesocket(s);
    return std::nullopt;
  }
  ::QueryPerformanceCounter(&end);
  ::closesocket(s);
  return static_cast<int>((end.QuadPart - start.QuadPart) * 1000 /
                          freq.QuadPart);
}

std::optional<int> QuicProbeMs(addrinfo* info, DWORD if_index,
                               int timeout_ms) {
  SOCKET s = ::socket(info->ai_family, info->ai_socktype, info->ai_protocol);
  if (s == INVALID_SOCKET) return std::nullopt;
  BindToInterface(s, info->ai_family, if_index);

  // connect на UDP только фиксирует адресата — датаграммы от чужих хостов
  // ядро отбросит само, и recv не придётся фильтровать руками.
  if (::connect(s, info->ai_addr, static_cast<int>(info->ai_addrlen)) != 0) {
    ::closesocket(s);
    return std::nullopt;
  }

  auto packet = QuicVersionNegotiationProbe();
  LARGE_INTEGER freq, start, end;
  ::QueryPerformanceFrequency(&freq);
  ::QueryPerformanceCounter(&start);
  int sent = ::send(s, packet.data(), static_cast<int>(packet.size()), 0);
  if (sent < 0) {
    ::closesocket(s);
    return std::nullopt;
  }

  fd_set read_set;
  FD_ZERO(&read_set);
  FD_SET(s, &read_set);
  timeval tv{timeout_ms / 1000, (timeout_ms % 1000) * 1000};
  int ready = ::select(0, &read_set, nullptr, nullptr, &tv);
  if (ready <= 0) {
    ::closesocket(s);
    return std::nullopt;
  }
  char scratch[1500];
  int recvd = ::recv(s, scratch, sizeof(scratch), 0);
  ::closesocket(s);
  if (recvd <= 0) return std::nullopt;
  ::QueryPerformanceCounter(&end);
  return static_cast<int>((end.QuadPart - start.QuadPart) * 1000 /
                          freq.QuadPart);
}

// Резолв адреса и перебор кандидатов до первого удачного замера.
std::optional<int> ResolveAndProbe(const std::string& host, int port,
                                   int socktype, int proto, bool udp,
                                   int timeout_ms) {
  DWORD if_index = PhysicalInterfaceIndex();

  addrinfo hints{};
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = socktype;
  hints.ai_protocol = proto;
  addrinfo* list = nullptr;
  if (::getaddrinfo(host.c_str(), std::to_string(port).c_str(), &hints,
                    &list) != 0 ||
      list == nullptr) {
    return std::nullopt;
  }
  std::optional<int> result;
  for (addrinfo* cur = list; cur != nullptr; cur = cur->ai_next) {
    result = udp ? QuicProbeMs(cur, if_index, timeout_ms)
                : ConnectMs(cur, if_index, timeout_ms);
    if (result.has_value()) break;
  }
  ::freeaddrinfo(list);
  return result;
}

}  // namespace

void RegisterBypassPingChannel(flutter::FlutterEngine* engine) {
  // Winsock не инициализирован больше нигде в runner — без WSAStartup любой
  // вызов socket() здесь вернёт WSANOTINITIALISED.
  static WSADATA wsa_data;
  ::WSAStartup(MAKEWORD(2, 2), &wsa_data);

  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "verge/bypass_ping",
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    const std::string& name = call.method_name();
    if (name != "tcpPing" && name != "udpPing") {
      result->NotImplemented();
      return;
    }
    bool udp = name == "udpPing";
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    const auto* host_val = args ? Find(*args, "host") : nullptr;
    const auto* port_val = args ? Find(*args, "port") : nullptr;
    if (host_val == nullptr || port_val == nullptr) {
      result->Error("ARG", "host/port required");
      return;
    }
    std::string host = std::get<std::string>(*host_val);
    int port = std::get<int>(*port_val);
    int timeout_ms = 3000;
    if (args != nullptr) {
      const auto* t = Find(*args, "timeoutMs");
      if (t != nullptr) timeout_ms = std::get<int>(*t);
    }

    // Замер блокирующий, поэтому уводится в поток — иначе UI встанет на всю
    // длительность таймаута.
    std::shared_ptr<flutter::MethodResult<EncodableValue>> shared =
        std::move(result);
    std::thread([shared, host, port, timeout_ms, udp]() {
      int socktype = udp ? SOCK_DGRAM : SOCK_STREAM;
      int proto = udp ? IPPROTO_UDP : IPPROTO_TCP;
      std::optional<int> ms =
          ResolveAndProbe(host, port, socktype, proto, udp, timeout_ms);
      // Результат отдаём с platform thread: MethodResult не потокобезопасен.
      PlatformTaskRunner::Post([shared, ms]() {
        if (ms.has_value()) {
          shared->Success(EncodableValue(*ms));
        } else {
          shared->Success();
        }
      });
    }).detach();
  });
  channel.release();
}
