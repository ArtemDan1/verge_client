import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/deep_link.dart';

void main() {
  group('parseVergeLink', () {
    test('валидная ссылка с name', () {
      final r = parseVergeLink(
          'verge://import/https%3A%2F%2Fexample.com%2Fsub?name=Test');
      expect(r, isNotNull);
      expect(r!.url, 'https://example.com/sub');
      expect(r.name, 'Test');
    });

    test('без name → имя = хост подписки', () {
      final r = parseVergeLink('verge://import/https%3A%2F%2Fsub.example.com%2Fx');
      expect(r, isNotNull);
      expect(r!.url, 'https://sub.example.com/x');
      expect(r.name, 'sub.example.com');
    });

    test('http допустим', () {
      final r = parseVergeLink('verge://import/http%3A%2F%2Fexample.com%2Fs');
      expect(r, isNotNull);
      expect(r!.url, 'http://example.com/s');
    });

    test('неверная схема → null', () {
      expect(parseVergeLink('clash://import/https%3A%2F%2Fexample.com'), isNull);
    });

    test('неверный host → null', () {
      expect(parseVergeLink('verge://open/https%3A%2F%2Fexample.com'), isNull);
    });

    test('не-http подписочный URL → null', () {
      expect(parseVergeLink('verge://import/ftp%3A%2F%2Fexample.com'), isNull);
    });

    test('пустой path → null', () {
      expect(parseVergeLink('verge://import/'), isNull);
    });

    test('мусор → null', () {
      expect(parseVergeLink('not a url'), isNull);
    });
  });
}
