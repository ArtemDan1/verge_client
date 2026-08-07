import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

/// Пинг в обход туннеля.
///
/// В TUN-режиме весь системный трафик уходит в utun, поэтому обычный
/// `Socket.connect` меряет туннель, а не сервер. Нативный канал
/// (macOS, [BypassPingChannel]) привязывает сокет к физическому интерфейсу
/// через `IP_BOUND_IF` и возвращает честное время установления соединения.
///
/// Возвращает миллисекунды или null, если ответа не было.
typedef BypassPinger = Future<int?> Function(String host, int port,
    {Duration timeout});

/// UDP-замер для протоколов поверх QUIC (hysteria2). [bypassTunnel] — мерить
/// мимо туннеля (TUN).
typedef UdpPinger = Future<int?> Function(String host, int port,
    {Duration timeout, bool bypassTunnel});

const _channel = MethodChannel('verge/bypass_ping');

Future<int?> bypassTcpPing(String host, int port,
    {Duration timeout = const Duration(seconds: 3)}) async {
  try {
    return await _channel.invokeMethod<int>('tcpPing', {
      'host': host,
      'port': port,
      'timeoutMs': timeout.inMilliseconds,
    });
  } on MissingPluginException {
    // Канала нет (не macOS или тестовая среда) — обходить нечего, меряем
    // обычным сокетом: пусть число будет не идеально честным, чем никаким.
    return _plainTcpPing(host, port, timeout);
  } catch (_) {
    // Любой другой сбой канала (в том числе неинициализированный биндинг в
    // тестовой среде) — «не дозвонились», не роняем вызывающий код.
    return null;
  }
}

/// Задержка до QUIC-сервера (hysteria2 и прочее поверх QUIC).
///
/// TCP-порта у такого сервера нет вовсе, поэтому обычный connect всегда даёт
/// таймаут. Вместо него шлём UDP-датаграмму с заведомо неподдерживаемой
/// версией QUIC: по RFC 9000 сервер обязан ответить Version Negotiation, что
/// и даёт RTT, не требуя ни пароля, ни разбора ответа. Любой ответ считаем
/// признаком живого сервера.
///
/// Работает, пока трафик не обфусцирован (salamander и подобные): такой
/// сервер молча отбрасывает всё, что не расшифровалось, и замер даст таймаут.
Future<int?> quicUdpPing(String host, int port,
    {Duration timeout = const Duration(seconds: 3),
    bool bypassTunnel = false}) async {
  if (!bypassTunnel) return _plainUdpPing(host, port, timeout);
  try {
    return await _channel.invokeMethod<int>('udpPing', {
      'host': host,
      'port': port,
      'timeoutMs': timeout.inMilliseconds,
    });
  } on MissingPluginException {
    return _plainUdpPing(host, port, timeout);
  } catch (_) {
    return null;
  }
}

/// Пакет, на который QUIC-сервер отвечает Version Negotiation: long header,
/// зарезервированная версия 0x0a0a0a0a, случайные connection id. Дополняется
/// до 1200 байт — датаграммы меньше этого размера сервер вправе отбросить.
Uint8List quicVersionNegotiationProbe([Random? random]) {
  final rnd = random ?? Random.secure();
  final packet = Uint8List(1200);
  var i = 0;
  packet[i++] = 0xC0; // long header, fixed bit
  // Версия из reserved-диапазона: поддерживать её сервер не может по
  // определению, значит обязан прислать список своих.
  packet.setRange(i, i + 4, const [0x0A, 0x0A, 0x0A, 0x0A]);
  i += 4;
  for (final _ in [0, 1]) {
    packet[i++] = 8; // длина connection id
    for (var b = 0; b < 8; b++) {
      packet[i++] = rnd.nextInt(256);
    }
  }
  // Остаток — нули: содержимое неважно, важен только размер датаграммы.
  return packet;
}

Future<int?> _plainTcpPing(String host, int port, Duration timeout) async {
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    sw.stop();
    socket.destroy();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}

Future<int?> _plainUdpPing(String host, int port, Duration timeout) async {
  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? sub;
  try {
    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty) return null;
    final target = addresses.first;
    socket = await RawDatagramSocket.bind(
        target.type == InternetAddressType.IPv6
            ? InternetAddress.anyIPv6
            : InternetAddress.anyIPv4,
        0);
    final answer = Completer<int>();
    final sw = Stopwatch()..start();
    // Ждём любой ответ: разбирать Version Negotiation незачем, сам факт
    // ответа уже означает, что сервер на этом порту живёт.
    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      if (socket?.receive() == null) return;
      if (!answer.isCompleted) answer.complete(sw.elapsedMilliseconds);
    });
    socket.send(quicVersionNegotiationProbe(), target, port);
    return await answer.future.timeout(timeout, onTimeout: () => -1).then(
        (ms) => ms < 0 ? null : ms);
  } catch (_) {
    return null;
  } finally {
    sub?.cancel();
    socket?.close();
  }
}
