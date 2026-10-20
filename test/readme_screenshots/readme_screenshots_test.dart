// Генератор скриншотов для README. Рендерит настоящий AppShell с демо-данными
// (фейковые туннели, подписка и Clash API) и реальными шрифтами приложения.
//
// Запуск:
//   VERGE_SCREENSHOTS=1 flutter test --update-goldens test/readme_screenshots
//
// Без VERGE_SCREENSHOTS тесты пропускаются, чтобы не мешать обычному прогону.
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/app/tray_popover_controller.dart';
import 'package:singbox_client/app/window_control_channel.dart';
import 'package:singbox_client/services/deep_link.dart';
import 'package:singbox_client/theme/app_theme.dart';
import 'package:singbox_client/ui/app_shell.dart';
import 'package:singbox_client/ui/tray_popover.dart';

import '../support/demo_app.dart';

final _enabled = Platform.environment.containsKey('VERGE_SCREENSHOTS');

const _windowSize = Size(1100, 720);
const _pixelRatio = 2.0;

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  while (tester.takeException() != null) {}
}

Widget _app(AppController c, Widget home, ThemeMode mode) => ShadApp(
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
      home: RepaintBoundary(key: _shotKey, child: home),
    );

final _shotKey = GlobalKey();

Future<void> _shoot(String name) async {
  await expectLater(
      find.byKey(_shotKey), matchesGoldenFile('../../docs/screenshots/$name.png'));
}

void main() {
  setUpAll(() async {
    if (_enabled) await loadAppFonts();
  });

  // index — пункт сайдбара: 0 Главная, 1 Настройки, 2 Логи, 3 Соединения,
  // 4 Роутинг.
  final shots = <(String, int, ThemeMode)>[
    ('home-light', 0, ThemeMode.light),
    ('home-dark', 0, ThemeMode.dark),
    ('connections', 3, ThemeMode.light),
    ('routing', 4, ThemeMode.light),
    ('settings', 1, ThemeMode.light),
    ('logs', 2, ThemeMode.dark),
  ];

  for (final (name, index, mode) in shots) {
    testWidgets('скриншот $name', (tester) async {
      debugDisableShadows = false;
      tester.view.physicalSize = _windowSize * _pixelRatio;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      final c = await demoController(tester);
      final deepLink = DeepLinkService();
      await tester.pumpWidget(_app(
        c,
        AppShell(
            controller: c,
            deepLink: deepLink,
            navIndex: ValueNotifier(index)),
        mode,
      ));
      await _pumpFrames(tester);
      await _shoot(name);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await c.disconnect();
        c.dispose();
        deepLink.dispose();
      });
      debugDisableShadows = true;
    }, skip: !_enabled);
  }

  testWidgets('скриншот tray', (tester) async {
    debugDisableShadows = false;
    const channel = MethodChannel('window/control');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    final c = await demoController(tester);
    final popover = TrayPopoverController(WindowControlChannel(channel),
        waitForFrame: () async {});
    await popover.toggle(TrayPopover.heightFor(c));
    tester.view.physicalSize =
        Size(TrayPopoverController.width, TrayPopover.heightFor(c)) *
            _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
        c, TrayPopover(controller: c, popover: popover), ThemeMode.dark));
    await _pumpFrames(tester);
    await _shoot('tray');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await c.disconnect();
      c.dispose();
    });
    debugDisableShadows = true;
  }, skip: !_enabled);
}
