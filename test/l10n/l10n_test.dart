import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/l10n/l10n.dart';

void main() {
  tearDown(() => setAppLocale(const Locale('ru')));

  test('в селекторе ровно поддерживаемые языки', () {
    expect(
      appLanguages.keys.toSet(),
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
    );
  });

  test('каждый язык загружается, плюралы и подстановки работают', () {
    for (final code in appLanguages.keys) {
      final s = lookupAppLocalizations(Locale(code));
      for (final n in [0, 1, 2, 5, 21]) {
        expect(s.serverCount(n), isNotEmpty, reason: code);
        expect(s.ruleCount(n), isNotEmpty, reason: code);
        expect(s.connectionCount(n), isNotEmpty, reason: code);
      }
      expect(
        s.healthCheckFailed('node-x', 1, 2),
        contains('node-x'),
        reason: code,
      );
    }
  });

  test('русские плюралы', () {
    final s = lookupAppLocalizations(const Locale('ru'));
    expect(s.serverCount(1), '1 сервер');
    expect(s.serverCount(3), '3 сервера');
    expect(s.serverCount(12), '12 серверов');
    expect(s.serverCount(21), '21 сервер');
  });

  group('resolveAppLocale', () {
    test('явный язык из настроек', () {
      expect(resolveAppLocale('fa'), const Locale('fa'));
    });

    test('системный: первый поддерживаемый из списка', () {
      expect(
        resolveAppLocale(null, const [Locale('ja'), Locale('zh', 'CN')]),
        const Locale('zh'),
      );
    });

    test('неподдерживаемый системный — английский', () {
      expect(resolveAppLocale(null, const [Locale('ja')]), const Locale('en'));
    });

    test('мусор в настройках — как системный', () {
      expect(resolveAppLocale('xx', const [Locale('de')]), const Locale('de'));
    });
  });

  test('setAppLocale переключает l10n', () {
    setAppLocale(const Locale('en'));
    expect(l10n.connect, 'Connect');
    setAppLocale(const Locale('ru'));
    expect(l10n.connect, 'Подключиться');
  });
}
