// Телефонная раскладка (Android): каждый раздел рендерится на узком экране с
// настоящими шрифтами приложения, и любой overflow валит тест.
//
// Скриншоты для README (docs/screenshots/android-*.png):
//   VERGE_SCREENSHOTS=1 flutter test --update-goldens test/ui/mobile_shell_test.dart
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/deep_link.dart';
import 'package:singbox_client/theme/app_theme.dart';
import 'package:singbox_client/ui/mobile_shell.dart';

import '../support/demo_app.dart';

final _shots = Platform.environment.containsKey('VERGE_SCREENSHOTS');

/// Индексы разделов — как в сайдбаре: 0 Главная, 1 Настройки, 2 Логи,
/// 3 Соединения, 4 Роутинг.
const _sections = {
  0: 'home',
  4: 'routing',
  3: 'connections',
  2: 'logs',
  1: 'settings',
};

Widget _app(AppController c, int index, ThemeMode mode, Key key) => ShadApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      materialThemeBuilder: (context, theme) => theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: kUiFontFamily,
          fontFamilyFallback: kEmojiFontFallback,
        ),
      ),
      home: RepaintBoundary(
        key: key,
        child: MobileShell(
          controller: c,
          deepLink: DeepLinkService(),
          navIndex: ValueNotifier(index),
        ),
      ),
    );

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadAppFonts);

  // 360×740 — узкий, но массовый экран; 412×915 — типичный современный.
  for (final size in const [Size(360, 740), Size(412, 915)]) {
    for (final MapEntry(key: index, value: name) in _sections.entries) {
      testWidgets('${size.width.toInt()}dp: $name без overflow',
          (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final c = await demoController(tester, tunOnly: true);
        final key = GlobalKey();
        await tester.pumpWidget(_app(c, index, ThemeMode.light, key));
        await _pumpFrames(tester);
        if (_shots && size.width == 412) {
          await expectLater(find.byKey(key),
              matchesGoldenFile('../../docs/screenshots/android-$name.png'));
        }
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await c.disconnect();
          c.dispose();
        });
      });
    }
  }
}
