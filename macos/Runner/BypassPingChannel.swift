import Darwin
import FlutterMacOS
import Foundation

/// MethodChannel `verge/bypass_ping`: TCP-connect до host:port в обход
/// туннеля.
///
/// В TUN-режиме sing-box поднимает utun и перехватывает системный роутинг —
/// обычный `Socket.connect` из Dart уходит внутрь туннеля, и «пинг до ноды»
/// меряет не сервер, а сам туннель. Единственный способ выйти мимо utun на
/// macOS — привязать сокет к физическому интерфейсу опцией `IP_BOUND_IF`
/// (аналог SO_BINDTODEVICE), которой у dart:io нет. Отсюда нативный канал.
final class BypassPingChannel {
  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "verge/bypass_ping", binaryMessenger: registrar.messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "tcpPing" || call.method == "udpPing" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let udp = call.method == "udpPing"
      guard let args = call.arguments as? [String: Any],
            let host = args["host"] as? String,
            let port = args["port"] as? Int else {
        result(FlutterError(code: "ARG", message: "host/port required",
                            details: nil))
        return
      }
      let timeoutMs = args["timeoutMs"] as? Int ?? 3000
      // Замер блокирующий — уводим с главного потока, иначе UI встаёт на
      // всю длительность таймаута.
      DispatchQueue.global(qos: .utility).async {
        let ms = udp
          ? BypassPing.quicProbeMs(host: host, port: port, timeoutMs: timeoutMs)
          : BypassPing.connectMs(host: host, port: port, timeoutMs: timeoutMs)
        DispatchQueue.main.async { result(ms) }
      }
    }
  }
}

enum BypassPing {
  // Константы задаём явно: имена из <netinet/in.h> в Swift не импортируются.
  private static let ipBoundIf: Int32 = 25       // IP_BOUND_IF
  private static let ipv6BoundIf: Int32 = 125    // IPV6_BOUND_IF

  /// Миллисекунды до установления TCP-соединения или nil, если не удалось.
  static func connectMs(host: String, port: Int, timeoutMs: Int) -> NSNumber? {
    resolveAndProbe(host: host, port: port, socktype: SOCK_STREAM,
                    proto: IPPROTO_TCP) { info, ifIndex in
      connectOnce(info, ifIndex: ifIndex, timeoutMs: timeoutMs)
    }
  }

  /// Миллисекунды до ответа QUIC-сервера (hysteria2) или nil.
  ///
  /// TCP-порта у такого сервера нет, поэтому шлём UDP-датаграмму с
  /// неподдерживаемой версией QUIC: по RFC 9000 сервер обязан ответить
  /// Version Negotiation. Разбирать ответ не нужно — важен сам факт и время.
  static func quicProbeMs(host: String, port: Int, timeoutMs: Int) -> NSNumber? {
    resolveAndProbe(host: host, port: port, socktype: SOCK_DGRAM,
                    proto: IPPROTO_UDP) { info, ifIndex in
      quicProbeOnce(info, ifIndex: ifIndex, timeoutMs: timeoutMs)
    }
  }

  /// Резолв адреса и перебор кандидатов до первого удачного замера.
  private static func resolveAndProbe(
    host: String, port: Int, socktype: Int32, proto: Int32,
    probe: (addrinfo, UInt32) -> Int?
  ) -> NSNumber? {
    let ifIndex = physicalInterfaceIndex()

    var hints = addrinfo()
    hints.ai_family = AF_UNSPEC
    hints.ai_socktype = socktype
    hints.ai_protocol = proto
    var list: UnsafeMutablePointer<addrinfo>?
    guard getaddrinfo(host, String(port), &hints, &list) == 0,
          let head = list else { return nil }
    defer { freeaddrinfo(head) }

    var candidate: UnsafeMutablePointer<addrinfo>? = head
    while let info = candidate {
      if let ms = probe(info.pointee, ifIndex) { return NSNumber(value: ms) }
      candidate = info.pointee.ai_next
    }
    return nil
  }

  private static func quicProbeOnce(_ info: addrinfo, ifIndex: UInt32,
                                    timeoutMs: Int) -> Int? {
    let fd = socket(info.ai_family, info.ai_socktype, info.ai_protocol)
    if fd < 0 { return nil }
    defer { close(fd) }
    bindToInterface(fd, family: info.ai_family, ifIndex: ifIndex)

    // connect на UDP только фиксирует адресата — датаграммы от чужих хостов
    // ядро отбросит само, и recv не придётся фильтровать руками.
    if connect(fd, info.ai_addr, info.ai_addrlen) != 0 { return nil }

    let packet = quicVersionNegotiationProbe()
    let started = DispatchTime.now()
    let sent = packet.withUnsafeBytes { buf in
      send(fd, buf.baseAddress, buf.count, 0)
    }
    if sent < 0 { return nil }

    var pfd = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
    if poll(&pfd, 1, Int32(timeoutMs)) <= 0 { return nil }
    var scratch = [UInt8](repeating: 0, count: 1500)
    if recv(fd, &scratch, scratch.count, 0) <= 0 { return nil }

    let elapsed = DispatchTime.now().uptimeNanoseconds
      - started.uptimeNanoseconds
    return Int(elapsed / 1_000_000)
  }

  /// Пакет с зарезервированной версией QUIC (0x0a0a0a0a) и случайными
  /// connection id, добитый до 1200 байт: датаграммы меньшего размера сервер
  /// вправе отбросить.
  private static func quicVersionNegotiationProbe() -> [UInt8] {
    var packet = [UInt8](repeating: 0, count: 1200)
    packet[0] = 0xC0 // long header, fixed bit
    packet[1...4] = [0x0A, 0x0A, 0x0A, 0x0A]
    var i = 5
    for _ in 0..<2 {
      packet[i] = 8 // длина connection id
      i += 1
      for _ in 0..<8 {
        packet[i] = UInt8.random(in: 0...255)
        i += 1
      }
    }
    return packet
  }

  /// Собственно обход туннеля: исходящие пакеты пойдут через физический
  /// интерфейс, минуя default route на utun.
  private static func bindToInterface(_ fd: Int32, family: Int32,
                                      ifIndex: UInt32) {
    guard ifIndex != 0 else { return }
    var idx = ifIndex
    let level = family == AF_INET6 ? IPPROTO_IPV6 : IPPROTO_IP
    let name = family == AF_INET6 ? ipv6BoundIf : ipBoundIf
    setsockopt(fd, level, name, &idx, socklen_t(MemoryLayout<UInt32>.size))
  }

  private static func connectOnce(_ info: addrinfo, ifIndex: UInt32,
                                  timeoutMs: Int) -> Int? {
    let fd = socket(info.ai_family, info.ai_socktype, info.ai_protocol)
    if fd < 0 { return nil }
    defer { close(fd) }

    bindToInterface(fd, family: info.ai_family, ifIndex: ifIndex)

    let flags = fcntl(fd, F_GETFL, 0)
    _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

    let started = DispatchTime.now()
    let rc = connect(fd, info.ai_addr, info.ai_addrlen)
    if rc != 0 {
      if errno != EINPROGRESS { return nil }
      var pfd = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
      let ready = poll(&pfd, 1, Int32(timeoutMs))
      if ready <= 0 { return nil }
      var soError: Int32 = 0
      var len = socklen_t(MemoryLayout<Int32>.size)
      if getsockopt(fd, SOL_SOCKET, SO_ERROR, &soError, &len) != 0 { return nil }
      if soError != 0 { return nil }
    }
    let elapsed = DispatchTime.now().uptimeNanoseconds
      - started.uptimeNanoseconds
    return Int(elapsed / 1_000_000)
  }

  /// Индекс физического интерфейса с активным IPv4-адресом. utun/ipsec/ppp
  /// пропускаем — это и есть туннели, ради обхода которых всё затевается.
  /// 0 означает «не нашли»: тогда сокет никуда не привязываем и замер идёт
  /// обычным путём (лучше не совсем честное число, чем никакого).
  private static func physicalInterfaceIndex() -> UInt32 {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else { return 0 }
    defer { freeifaddrs(head) }

    var best: String?
    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let ifa = cursor {
      cursor = ifa.pointee.ifa_next
      guard let addr = ifa.pointee.ifa_addr,
            addr.pointee.sa_family == UInt8(AF_INET) else { continue }
      let flags = Int32(ifa.pointee.ifa_flags)
      guard flags & IFF_UP != 0, flags & IFF_RUNNING != 0,
            flags & IFF_LOOPBACK == 0 else { continue }
      let name = String(cString: ifa.pointee.ifa_name)
      if name.hasPrefix("utun") || name.hasPrefix("ipsec")
          || name.hasPrefix("ppp") || name.hasPrefix("tap")
          || name.hasPrefix("tun") { continue }
      // en0 — штатный Wi-Fi/Ethernet на маках; предпочитаем его любому
      // другому кандидату (bridge0, awdl0 и прочей экзотике).
      if name.hasPrefix("en") { return if_nametoindex(name) }
      if best == nil { best = name }
    }
    return best.map { if_nametoindex($0) } ?? 0
  }
}
