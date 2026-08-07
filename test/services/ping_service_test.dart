import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/bypass_ping.dart';
import 'package:singbox_client/services/ping_service.dart';

NodeConfig _node(String host, int port,
        {NodeProtocol protocol = NodeProtocol.vless}) =>
    NodeConfig(
        name: 'n', protocol: protocol, host: host, port: port,
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

  group('hysteria2 (QUIC поверх UDP)', () {
    test('меряется UDP-пробой, а не TCP-коннектом', () async {
      var tcpCalls = 0;
      String? udpHost;
      var udpBypass = true;
      final svc = PingService(
        connect: (host, port, {timeout}) async {
          tcpCalls++;
          throw const SocketException('у hysteria2 нет TCP-порта');
        },
        udpPing: (host, port,
            {timeout = const Duration(seconds: 3),
            bypassTunnel = false}) async {
          udpHost = host;
          udpBypass = bypassTunnel;
          return 12;
        },
      );

      final res = await svc
          .ping(_node('h', 443, protocol: NodeProtocol.hysteria2));

      expect(res.latencyMs, 12);
      expect(tcpCalls, 0);
      expect(udpHost, 'h');
      expect(udpBypass, isFalse);
    });

    test('bypassTunnel прокидывается в UDP-пробу', () async {
      var udpBypass = false;
      final svc = PingService(
        udpPing: (host, port,
            {timeout = const Duration(seconds: 3),
            bypassTunnel = false}) async {
          udpBypass = bypassTunnel;
          return 12;
        },
      );

      await svc.ping(_node('h', 443, protocol: NodeProtocol.hysteria2),
          bypassTunnel: true);

      expect(udpBypass, isTrue);
    });

    test('молчащий сервер → timedOut', () async {
      final svc = PingService(
        udpPing: (host, port,
                {timeout = const Duration(seconds: 3),
                bypassTunnel = false}) async =>
            null,
      );

      final res = await svc
          .ping(_node('h', 443, protocol: NodeProtocol.hysteria2));

      expect(res.latencyMs, isNull);
      expect(res.timedOut, isTrue);
    });

    test('vless по-прежнему меряется TCP-коннектом', () async {
      var udpCalls = 0;
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final svc = PingService(
        udpPing: (host, port,
            {timeout = const Duration(seconds: 3),
            bypassTunnel = false}) async {
          udpCalls++;
          return 12;
        },
      );

      final res = await svc.ping(_node('127.0.0.1', server.port));

      expect(res.latencyMs, isNotNull);
      expect(udpCalls, 0);
    });
  });

  group('QUIC-проба', () {
    test('пакет: 1200 байт, long header, зарезервированная версия', () {
      final packet = quicVersionNegotiationProbe();
      expect(packet.length, 1200);
      expect(packet[0] & 0xC0, 0xC0);
      expect(packet.sublist(1, 5), [0x0A, 0x0A, 0x0A, 0x0A]);
      // Длины connection id: по 8 байт каждый.
      expect(packet[5], 8);
      expect(packet[14], 8);
    });

    test('отвечающий UDP-сервер даёт число, молчащий — null', () async {
      final server = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = server.receive();
        if (dg == null) return;
        server.send([1], dg.address, dg.port);
      });

      expect(await quicUdpPing('127.0.0.1', server.port), isNotNull);

      // Порт, где никто не слушает: ICMP port unreachable в ответ не
      // приходит как датаграмма — ждём таймаут.
      final silent = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4, 0);
      final deadPort = silent.port;
      silent.close();
      expect(
          await quicUdpPing('127.0.0.1', deadPort,
              timeout: const Duration(milliseconds: 300)),
          isNull);
    });
  });
}
