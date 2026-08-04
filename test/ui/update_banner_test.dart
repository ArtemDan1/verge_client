import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/connection_info.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/services/update_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/widgets/sidebar.dart';
import 'package:singbox_client/ui/widgets/update_banner.dart';

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

class FakeUpdateService extends UpdateService {
  FakeUpdateService({this.info});
  final UpdateInfo? info;
  @override
  Future<UpdateInfo?> checkForUpdate(String currentVersion) async => info;
}

/// Собирает контроллер с заданным результатом проверки обновлений и
/// прогоняет init(), после которого checkForUpdateSilently уже отработала.
/// tester.pump() обязателен: чистый await Future.delayed внутри testWidgets
/// не продвигает фейковые часы биндинга и вешает тест.
Future<AppController> controllerWithUpdate(
    WidgetTester tester, UpdateInfo? info) async {
  final c = AppController(
    subscription: SubscriptionService(
        fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
    builder: const ConfigBuilder(),
    proxyTunnel: FakeTunnel(),
    tunTunnel: FakeTunnel(),
    repo: InMemoryStateRepository(),
    platform: FakePlatformInfo(),
    updateService: FakeUpdateService(info: info),
    timerFactory: (duration, callback) => Timer(Duration.zero, () {}),
  );
  await c.init();
  await tester.pump();
  return c;
}

void main() {
  testWidgets('баннер скрыт, когда обновления нет', (tester) async {
    final c = await controllerWithUpdate(tester, null);
    await tester.pumpWidget(ShadApp(home: UpdateBanner(controller: c)));
    expect(find.textContaining('Доступна версия'), findsNothing);
    // Реальный периодический таймер автообновления должен быть отменён
    // до конца теста — иначе flutter_test падает на pending timer.
    c.dispose();
  });

  testWidgets('баннер показывает версию и три действия', (tester) async {
    final c = await controllerWithUpdate(tester, const UpdateInfo(
      version: 'v9.9.9', pkgUrl: 'https://e/x.pkg', releaseUrl: 'https://e',
    ));
    await tester.pumpWidget(ShadApp(home: UpdateBanner(controller: c)));
    expect(find.text('Доступна версия v9.9.9'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
    expect(find.text('Позже'), findsOneWidget);
    expect(find.text('Пропустить версию'), findsOneWidget);
    c.dispose();
  });

  testWidgets('«Позже» скрывает баннер', (tester) async {
    final c = await controllerWithUpdate(tester, const UpdateInfo(
      version: 'v9.9.9', pkgUrl: 'https://e/x.pkg', releaseUrl: 'https://e',
    ));
    await tester.pumpWidget(ShadApp(
      home: AnimatedBuilder(
        animation: c,
        builder: (_, _) => UpdateBanner(controller: c),
      ),
    ));
    await tester.tap(find.text('Позже'));
    await tester.pump();
    expect(find.textContaining('Доступна версия'), findsNothing);
    c.dispose();
  });

  testWidgets('бейдж на «О приложении» появляется при обновлении',
      (tester) async {
    await tester.pumpWidget(ShadApp(
      home: Sidebar(
        index: 0, onSelect: (_) {}, connectionCount: 0,
        traffic: const TrafficStats(upSpeed: 0, downSpeed: 0, upTotal: 0, downTotal: 0),
        hasUpdate: true,
      ),
    ));
    expect(find.byKey(const Key('update-dot')), findsOneWidget);
  });
}
