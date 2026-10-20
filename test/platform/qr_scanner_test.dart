import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/platform/qr_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('verge/qr');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('URL подписки и share-ссылка отдаются как есть', () {
    expect(normalizeScannedLink('  https://sub.example/abc \n'),
        'https://sub.example/abc');
    expect(normalizeScannedLink('vless://u@h:443#A'), 'vless://u@h:443#A');
  });

  test('из verge://import берётся сама подписка', () {
    final link =
        'verge://import/${Uri.encodeComponent('https://sub.example/x?t=1')}';
    expect(normalizeScannedLink(link), 'https://sub.example/x?t=1');
  });

  test('закрытый сканер — null, ошибка — понятное исключение', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await const QrScanner().scan(), isNull);

    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'SCAN', message: 'нет сервисов Google');
    });
    expect(const QrScanner().scan(),
        throwsA(isA<QrScanException>()
            .having((e) => e.message, 'message', 'нет сервисов Google')));
  });
}
