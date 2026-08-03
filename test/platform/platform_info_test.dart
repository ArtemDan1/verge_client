import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/platform/platform_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('singbox/tunnel');

  test('версии движков и listNetworkServices через канал', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'singboxVersion':
          return '1.13.12';
        case 'xrayVersion':
          return '26.3.27';
        case 'listNetworkServices':
          return ['Wi-Fi', 'Ethernet'];
        case 'defaultService':
          return 'Wi-Fi';
      }
      return null;
    });

    final info = PlatformInfo();
    expect(await info.singboxVersion(), '1.13.12');
    expect(await info.xrayVersion(), '26.3.27');
    expect(await info.listNetworkServices(), ['Wi-Fi', 'Ethernet']);
    expect(await info.defaultService(), 'Wi-Fi');
  });

  test('канал молчит про версию Xray → unknown, а не падение экрана', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    expect(await PlatformInfo().xrayVersion(), 'unknown');
  });
}
