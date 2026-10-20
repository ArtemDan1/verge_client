import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/tunnel/android_vpn_tunnel.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('singbox/tun');
  const events = 'singbox/tun/events';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Шлёт событие в EventChannel, как нативная сторона.
  Future<void> push(Map<String, Object?> event) async {
    await messenger.handlePlatformMessage(
      events,
      const StandardMethodCodec().encodeSuccessEnvelope(event),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    // EventChannel ждёт ответа на listen/cancel.
    messenger.setMockMethodCallHandler(
        const MethodChannel(events), (call) async => null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(const MethodChannel(events), null);
  });

  test('start шлёт конфиг строкой и эмитит connecting → connected', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final tunnel = AndroidVpnTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await tunnel.start({'outbounds': []}, port: 2080, service: '');
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.method, 'start');
    final sent = jsonDecode(calls.single.arguments['config'] as String);
    expect(sent['outbounds'], isEmpty);
    expect(seen, [TunnelStatus.connecting, TunnelStatus.connected]);
  });

  test('событие о том же статусе, что уже известен из ответа, не дублируется',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      // Нативная сторона сначала шлёт событие, потом отвечает на start.
      await push({'type': 'status', 'value': 'connected'});
      return null;
    });
    final tunnel = AndroidVpnTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await tunnel.start({}, port: 2080, service: '');
    await Future<void>.delayed(Duration.zero);

    expect(seen, [TunnelStatus.connecting, TunnelStatus.connected]);
  });

  test('ошибка старта: одна ошибка с текстом ядра', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      await push({
        'type': 'status',
        'value': 'error',
        'message': 'decode config: bad',
      });
      throw PlatformException(code: 'START', message: 'decode config: bad');
    });
    final tunnel = AndroidVpnTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await tunnel.start({}, port: 2080, service: '');
    await Future<void>.delayed(Duration.zero);

    expect(seen, [TunnelStatus.connecting, TunnelStatus.error]);
    expect(tunnel.lastError, 'decode config: bad');
  });

  test('VPN отключили из системы — приходит disconnected', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final tunnel = AndroidVpnTunnel();
    await tunnel.start({}, port: 2080, service: '');
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await push({'type': 'status', 'value': 'disconnected'});

    expect(seen, [TunnelStatus.disconnected]);
  });

  test('логи ядра идут в logStream', () async {
    final tunnel = AndroidVpnTunnel();
    final lines = <String>[];
    tunnel.logStream.listen(lines.add);
    await Future<void>.delayed(Duration.zero);

    await push({'type': 'log', 'line': 'INFO sing-box started'});

    expect(lines, ['INFO sing-box started']);
  });

  test('attach: работающий VPN отдаёт конфиг и переводит в connected',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'state');
      return {
        'status': 'connected',
        'config': jsonEncode({'outbounds': []}),
      };
    });
    final tunnel = AndroidVpnTunnel();
    final config = await tunnel.attach();
    expect(config, {'outbounds': []});
    expect(tunnel.status, TunnelStatus.connected);
  });

  test('attach: VPN не поднят — null, статус не меняется', () async {
    messenger.setMockMethodCallHandler(
        channel, (call) async => {'status': 'disconnected', 'config': null});
    final tunnel = AndroidVpnTunnel();
    expect(await tunnel.attach(), isNull);
    expect(tunnel.status, TunnelStatus.disconnected);
  });
}
