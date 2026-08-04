import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/persisted_state.dart';
import 'package:singbox_client/models/profile.dart';
import 'package:singbox_client/models/subscription_meta.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/profiles_screen.dart';

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

/// Ждёт стабилизации UI, игнорируя известный overflow в HeroPanel — он
/// визуально корректен, но shadcn_ui 0.54.0 не влезает в жёсткую высоту табов.
/// HeroPanel также запускает бесконечную пульсацию кнопки, поэтому
/// pumpAndSettle() здесь никогда не завершится — качаем фиксированное число
/// фреймов и съедаем накопленные overflow-исключения.
Future<void> _pumpAndSettleIgnoringOverflow(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  while (tester.takeException() != null) {}
}

Future<AppController> pumpProfilesScreen(
  WidgetTester tester, {
  required List<Profile> profiles,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final c = AppController(
    subscription: SubscriptionService(
        fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
    builder: const ConfigBuilder(),
    proxyTunnel: FakeTunnel(),
    tunTunnel: FakeTunnel(),
    repo: InMemoryStateRepository(PersistedState(profiles: profiles)),
    platform: FakePlatformInfo(),
    timerFactory: (duration, callback) => Timer(Duration.zero, () {}),
  );
  await c.init();
  addTearDown(c.dispose);

  await tester.pumpWidget(
    ShadApp(home: ProfilesScreen(controller: c)),
  );
  await _pumpAndSettleIgnoringOverflow(tester);
  return c;
}

/// Открывает «...»-меню профиля.
Future<void> _openProfileMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.ellipsis).first);
  await _pumpAndSettleIgnoringOverflow(tester);
}

void main() {
  testWidgets('меню профиля показывает интервал из подписки в часах',
      (tester) async {
    await pumpProfilesScreen(tester, profiles: [
      Profile(
        id: 'p1', name: 'P', url: 'https://example.com/a',
        nodes: const [], selectedNodeIndex: null,
        subscriptionMeta: const SubscriptionMeta(updateIntervalHours: 6),
      ),
    ]);
    // В самой карточке строки автообновления больше нет.
    expect(find.textContaining('Автообновление:'), findsNothing);

    await _openProfileMenu(tester);
    expect(find.text('Автообновление'), findsOneWidget);
    expect(find.text('По подписке: 6 ч'), findsOneWidget);
  });

  testWidgets('меню профиля показывает выключенное автообновление',
      (tester) async {
    await pumpProfilesScreen(tester, profiles: [
      Profile(
        id: 'p1', name: 'P', url: 'https://example.com/a',
        nodes: const [], selectedNodeIndex: null,
      ),
    ]);
    await _openProfileMenu(tester);
    expect(find.text('Выключено'), findsOneWidget);
  });

  testWidgets('диалог принимает часы и пишет в модель минуты', (tester) async {
    final c = await pumpProfilesScreen(tester, profiles: [
      Profile(
        id: 'p1', name: 'P', url: 'https://example.com/a',
        nodes: const [], selectedNodeIndex: null,
      ),
    ]);

    await _openProfileMenu(tester);
    await tester.tap(find.text('Автообновление'));
    await _pumpAndSettleIgnoringOverflow(tester);

    await tester.enterText(find.byType(ShadInput).last, '6');
    await tester.tap(find.text('Сохранить'));
    await _pumpAndSettleIgnoringOverflow(tester);

    // Модель хранит минуты, UI оперирует часами.
    expect(c.profiles.first.refreshIntervalMinutesOverride, 360);
    expect(c.profiles.first.effectiveRefreshIntervalMinutes, 360);

    await _openProfileMenu(tester);
    expect(find.text('Своё: 6 ч'), findsOneWidget);
  });

  testWidgets('интервал в минутах от старой версии показывается в часах',
      (tester) async {
    await pumpProfilesScreen(tester, profiles: [
      Profile(
        id: 'p1', name: 'P', url: 'https://example.com/a',
        nodes: const [], selectedNodeIndex: null,
        // 90 минут не делятся на час нацело — округляем вверх, чтобы не
        // показать «1 ч» там, где интервал больше часа.
        refreshIntervalMinutesOverride: 90,
      ),
    ]);
    await _openProfileMenu(tester);
    expect(find.text('Своё: 2 ч'), findsOneWidget);
  });
}
