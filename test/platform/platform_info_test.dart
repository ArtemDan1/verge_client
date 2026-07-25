import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/platform/platform_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('singbox/tunnel');

  test('singboxVersion и listNetworkServices через канал', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'singboxVersion':
          return '1.13.12';
        case 'listNetworkServices':
          return ['Wi-Fi', 'Ethernet'];
        case 'defaultService':
          return 'Wi-Fi';
      }
      return null;
    });

    final info = PlatformInfo();
    expect(await info.singboxVersion(), '1.13.12');
    expect(await info.listNetworkServices(), ['Wi-Fi', 'Ethernet']);
    expect(await info.defaultService(), 'Wi-Fi');
  });
}
