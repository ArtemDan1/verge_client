import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/tunnel/tun_helper_tunnel.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('singbox/tun');

  test('start шлёт config и эмитит connecting→connected', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    final tunnel = TunHelperTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await tunnel.start({'outbounds': []}, port: 2080, service: '');

    expect(calls.single.method, 'start');
    final sent = jsonDecode(calls.single.arguments['config'] as String);
    expect(sent['outbounds'], isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [TunnelStatus.connecting, TunnelStatus.connected]);
  });

  test('PlatformException → status error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'START', message: 'helper down');
    });
    final tunnel = TunHelperTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);
    await tunnel.start({}, port: 2080, service: '');
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, TunnelStatus.error);
  });
}
