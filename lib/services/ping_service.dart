import 'dart:async';
import 'dart:io';
import '../models/node_config.dart';

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
  PingService({SocketConnector? connect}) : _connect = connect ?? _defaultConnect;

  Future<PingResult> ping(NodeConfig node,
      {Duration timeout = const Duration(seconds: 3)}) async {
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
