import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/ping_service.dart';

NodeConfig _node(String host, int port) => NodeConfig(
      name: 'n', protocol: NodeProtocol.vless, host: host, port: port,
      params: const {});

void main() {
  test('успешный connect возвращает latencyMs', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final svc = PingService();
    final res = await svc.ping(_node('127.0.0.1', server.port));
    expect(res.latencyMs, isNotNull);
    expect(res.timedOut, isFalse);
    expect(res.error, isNull);
  });

  test('таймаут соединения → timedOut', () async {
    final svc = PingService(connect: (host, port, {timeout}) =>
        Future.error(const SocketException('connection timed out')));
    final res = await svc.ping(_node('h', 443),
        timeout: const Duration(milliseconds: 100));
    expect(res.latencyMs, isNull);
    expect(res.timedOut, isTrue);
  });

  test('отказ соединения → error, latencyMs == null', () async {
    final svc = PingService(connect: (host, port, {timeout}) => Future.error(
        const SocketException('refused',
            osError: OSError('Connection refused', 61))));
    final res = await svc.ping(_node('h', 443));
    expect(res.latencyMs, isNull);
    expect(res.error ?? '', isNotEmpty);
  });
}
