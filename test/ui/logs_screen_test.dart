import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/ui/logs_screen.dart';
import '../app/app_controller_test.dart' show FakeTunnel, FakePlatformInfo;

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  late FakeTunnel proxy;
  late AppController controller;

  setUp(() {
    proxy = FakeTunnel();
    controller = AppController(
      subscription:
          SubscriptionService(fetcher: (_) async => FetchResult('', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: proxy,
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
          null,
      bypassProbe: (host, port, {timeout = const Duration(seconds: 3)}) async =>
          null,
    );
  });

  /// Наполняет лог: строка от самого приложения и строка от ядра sing-box
  /// (она приходит потоком туннеля).
  Future<void> fill(WidgetTester t) async {
    await controller.init();
    proxy.emitLog('INFO router: loaded rule-set');
    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: controller,
      builder: (_, _) => LogsScreen(controller: controller),
    )));
    await t.pump();
  }

  testWidgets('строки помечены источником', (t) async {
    await fill(t);

    expect(find.textContaining('loaded rule-set'), findsOneWidget);
    // Бейдж источника у строки ядра.
    expect(find.text('sing-box'), findsWidgets);

    // Таймеры контроллера реальные — гасим до конца теста.
    controller.dispose();
  });

  testWidgets('фильтр по источнику скрывает чужие строки', (t) async {
    await fill(t);
    expect(find.textContaining('loaded rule-set'), findsOneWidget);

    // Чип «app» — в фильтрах он первый из источников.
    await t.tap(find.text('app').first);
    await t.pumpAndSettle();

    expect(find.textContaining('loaded rule-set'), findsNothing);
    // Бейджей источника sing-box в списке не осталось (фильтры не в счёт —
    // они выше и всегда показывают все варианты).
    expect(find.text('sing-box'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('фильтр по уровню оставляет только выбранный уровень',
      (t) async {
    await fill(t);
    proxy.emitLog('ERROR outbound: dial failed');
    await t.pump();

    expect(find.textContaining('dial failed'), findsOneWidget);
    expect(find.textContaining('loaded rule-set'), findsOneWidget);

    await t.tap(find.text('ERROR').first);
    await t.pumpAndSettle();

    expect(find.textContaining('dial failed'), findsOneWidget);
    expect(find.textContaining('loaded rule-set'), findsNothing);

    controller.dispose();
  });

  testWidgets('сброс возвращает все строки', (t) async {
    await fill(t);
    await t.tap(find.text('app').first);
    await t.pumpAndSettle();
    expect(find.textContaining('loaded rule-set'), findsNothing);

    await t.tap(find.text('Сбросить'));
    await t.pumpAndSettle();

    expect(find.textContaining('loaded rule-set'), findsOneWidget);

    controller.dispose();
  });
}
