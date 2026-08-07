import 'dart:async';
import 'dart:io';
import '../models/node_config.dart';
import 'bypass_ping.dart';

/// Устанавливает TCP-соединение до host:port. Инъектируется в тестах.
typedef SocketConnector = Future<Socket> Function(
    String host, int port, {Duration? timeout});

Future<Socket> _defaultConnect(String host, int port, {Duration? timeout}) =>
    Socket.connect(host, port, timeout: timeout);

class PingResult {
  final int? latencyMs;
  final bool timedOut;
  final String? error;

  const PingResult.ok(this.latencyMs) : timedOut = false, error = null;
  const PingResult.timeout() : latencyMs = null, timedOut = true, error = null;
  const PingResult.failure(this.error) : latencyMs = null, timedOut = false;
}

class PingService {
  final SocketConnector _connect;
  final BypassPinger _bypass;
  final UdpPinger _udpPing;
  PingService({
    SocketConnector? connect,
    BypassPinger? bypassPing,
    UdpPinger? udpPing,
  })  : _connect = connect ?? _defaultConnect,
        _bypass = bypassPing ?? bypassTcpPing,
        _udpPing = udpPing ?? quicUdpPing;

  /// [bypassTunnel] — мерить мимо туннеля (нужно в TUN-режиме, где обычный
  /// сокет перехватывается utun и меряет туннель, а не сервер).
  Future<PingResult> ping(NodeConfig node,
      {Duration timeout = const Duration(seconds: 3),
      bool bypassTunnel = false}) async {
    // hysteria2 живёт поверх QUIC: TCP-порта у сервера нет вовсе, и обычный
    // connect всегда давал бы таймаут на живой ноде.
    if (node.protocol == NodeProtocol.hysteria2) {
      final ms = await _udpPing(node.host, node.port,
          timeout: timeout, bypassTunnel: bypassTunnel);
      return ms == null ? const PingResult.timeout() : PingResult.ok(ms);
    }
    if (bypassTunnel) {
      final ms = await _bypass(node.host, node.port, timeout: timeout);
      // Нативный замер не различает отказ и таймаут — показываем таймаут:
      // для пользователя разница только в слове на чипе.
      return ms == null ? const PingResult.timeout() : PingResult.ok(ms);
    }
    final sw = Stopwatch()..start();
    try {
      final socket = await _connect(node.host, node.port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return PingResult.ok(sw.elapsedMilliseconds);
    } on SocketException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.osError == null || msg.contains('timed out') || msg.contains('timeout')) {
        return const PingResult.timeout();
      }
      return PingResult.failure(e.osError?.message ?? e.message);
    } catch (e) {
      return PingResult.failure(e.toString());
    }
  }
}
