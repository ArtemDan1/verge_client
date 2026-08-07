import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/settings_screen.dart';

class FakeTunnel extends TunnelController {
  @override
  Future<void> start(Map<String, dynamic> config,
          {required int port, required String service}) async =>
      emit(TunnelStatus.connected);
  @override
  Future<void> stop() async => emit(TunnelStatus.disconnected);
}

class FakePlatformInfo extends PlatformInfo {
  @override
  Future<List<String>> listNetworkServices() async => ['Wi-Fi'];
  @override
  Future<String?> defaultService() async => 'Wi-Fi';
  @override
  Future<String> singboxVersion() async => '1.13.12';
  @override
  Future<String> xrayVersion() async => '26.3.27';
  @override
  Future<String> appVersion() async => '1.0.0+1';
}

AppController buildController() => AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      timerFactory: (duration, callback) => Timer(Duration.zero, () {}),
    );

void main() {
  late AppController c;

  setUp(() {
    c = buildController();
  });

  /// Экран настроек с задачи 16-17 не влезает в дефолтные 800x600 теста —
  /// нижние секции (TUN, TLS) остаются за пределами root render tree, и
  /// tap() по ним не хит-тестится. Высокое окно — способ проще, чем
  /// прокручивать вручную перед каждым tap().
  void useTallWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('экран настроек показывает тему, порт и автозапуск',
      (tester) async {
    await c.init();
    await tester.pumpWidget(ShadApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Локальный порт прокси'), findsOneWidget);
    expect(find.text('Автозапуск'), findsOneWidget);
    expect(find.text('Автообновление подписок'), findsNothing);
    c.dispose();
  });

  testWidgets('переключатель IPv6 меняет сетевые настройки', (tester) async {
    await c.init();
    await tester.pumpWidget(ShadApp(
      home: AnimatedBuilder(
        animation: c,
        builder: (_, _) => SettingsScreen(controller: c),
      ),
    ));
    await tester.pumpAndSettle();
    expect(c.networkSettings.ipv6Enabled, isFalse);

    // Секций стало больше — переключатель может быть за пределами экрана.
    await tester.ensureVisible(find.byKey(const Key('ipv6-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ipv6-switch')));
    await tester.pumpAndSettle();

    expect(c.networkSettings.ipv6Enabled, isTrue);
    c.dispose();
  });

  testWidgets('секция DNS показывает серверы и способ разрешения',
      (tester) async {
    await c.init();
    await tester.pumpWidget(ShadApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('DNS'), findsOneWidget);
    expect(find.text('Перехват DNS в TUN'), findsOneWidget);
    expect(find.text('DNS для прокси'), findsOneWidget);
    expect(find.text('DNS для прямых соединений'), findsOneWidget);
    c.dispose();
  });

  testWidgets('параметры TUN скрыты под спойлером', (tester) async {
    useTallWindow(tester);
    await c.init();
    await tester.pumpWidget(ShadApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('MTU'), findsNothing);

    await tester.tap(find.text('Расширенные'));
    await tester.pumpAndSettle();

    expect(find.text('MTU'), findsOneWidget);
    expect(find.textContaining('Менять эти значения'), findsOneWidget);
    c.dispose();
  });

  testWidgets('«Сбросить» возвращает параметры TUN к умолчанию',
      (tester) async {
    useTallWindow(tester);
    await c.init();
    await c.updateNetworkSettings(
        c.networkSettings.copyWith(tunMtu: 1500, tunStrictRoute: true));
    await tester.pumpWidget(ShadApp(
      home: AnimatedBuilder(
        animation: c,
        builder: (_, _) => SettingsScreen(controller: c),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расширенные'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();

    expect(c.networkSettings.tunMtu, 4064);
    expect(c.networkSettings.tunStrictRoute, isFalse);
    c.dispose();
  });

  testWidgets('секция TLS показывает пропуск проверки сертификата',
      (tester) async {
    await c.init();
    await tester.pumpWidget(ShadApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('Пропустить проверку сертификата'), findsOneWidget);
    c.dispose();
  });

  testWidgets('переключатель фрагментации TLS меняет сетевые настройки',
      (tester) async {
    useTallWindow(tester);
    await c.init();
    await tester.pumpWidget(ShadApp(
      home: AnimatedBuilder(
        animation: c,
        builder: (_, _) => SettingsScreen(controller: c),
      ),
    ));
    await tester.pumpAndSettle();
    expect(c.networkSettings.tlsFragmentEnabled, isFalse);

    await tester.tap(find.byKey(const Key('tls-fragment-switch')));
    await tester.pumpAndSettle();

    expect(c.networkSettings.tlsFragmentEnabled, isTrue);
    // Поля фрагментации появляются только после включения тумблера.
    expect(find.text('Фрагментация по TLS-записям'), findsOneWidget);
    expect(find.text('Задержка резервного варианта'), findsOneWidget);
    c.dispose();
  });
}
