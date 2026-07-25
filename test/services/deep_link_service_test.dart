import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/deep_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app/deeplink');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('onLink с валидной ссылкой попадает в stream', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getInitialLink') return null;
      return null;
    });
    final service = DeepLinkService();
    await service.init();

    final future = service.imports.first;

    // Эмулируем нативный вызов onLink → Flutter.
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall(
          'onLink', 'verge://import/https%3A%2F%2Fexample.com%2Fsub?name=T')),
      (_) {},
    );

    final req = await future;
    expect(req.url, 'https://example.com/sub');
    expect(req.name, 'T');
    service.dispose();
  });

  test('getInitialLink с холодного старта попадает в stream', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getInitialLink') {
        return 'verge://import/https%3A%2F%2Fcold.example.com%2Fx';
      }
      return null;
    });
    final service = DeepLinkService();
    final future = service.imports.first;
    await service.init();
    final req = await future;
    expect(req.url, 'https://cold.example.com/x');
    expect(req.name, 'cold.example.com');
    service.dispose();
  });

  test('невалидная ссылка не эмитится', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final service = DeepLinkService();
    await service.init();
    var emitted = false;
    final sub = service.imports.listen((_) => emitted = true);
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
          const MethodCall('onLink', 'clash://import/https%3A%2F%2Fx.com')),
      (_) {},
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emitted, isFalse);
    await sub.cancel();
    service.dispose();
  });
}
