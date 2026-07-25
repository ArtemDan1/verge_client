import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/tunnel/macos_process_tunnel.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('singbox/tunnel');

  test('start шлёт config+port+service и эмитит connected', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    final tunnel = MacOSProcessTunnel();
    final seen = <TunnelStatus>[];
    tunnel.statusStream.listen(seen.add);

    await tunnel.start({'outbounds': []}, port: 1080, service: 'Wi-Fi');

    expect(calls.single.method, 'start');
    final args = calls.single.arguments as Map;
    expect(jsonDecode(args['config'] as String)['outbounds'], isEmpty);
    expect(args['port'], 1080);
    expect(args['service'], 'Wi-Fi');
    await Future<void>.delayed(Duration.zero);
    expect(seen, contains(TunnelStatus.connected));
  });
}
