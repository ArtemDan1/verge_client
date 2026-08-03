import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/deep_link.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/app_shell.dart';
import 'package:singbox_client/ui/widgets/sidebar.dart';
import 'package:singbox_client/models/connection_info.dart';

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

void main() {
  testWidgets('AppShell рендерит пункты сайдбара и переключает на Настройки',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final c = AppController(
      subscription: SubscriptionService(fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
    );
    final deepLink = DeepLinkService();
    addTearDown(deepLink.dispose);
    await c.init();
    await tester.pumpWidget(ShadApp(home: AppShell(controller: c, deepLink: deepLink)));
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Роутинг'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Логи'), findsOneWidget);
    expect(find.text('О приложении'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.text('Автозапуск'), findsOneWidget);
  });

  testWidgets('сайдбар показывает пункт «Соединения» с badge и трафик',
      (tester) async {
    await tester.pumpWidget(ShadApp(
      home: Sidebar(
        index: 0,
        onSelect: (_) {},
        connectionCount: 0,
        traffic: TrafficStats.zero,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Соединения'), findsOneWidget);
    expect(find.text('О приложении'), findsOneWidget);
    // Трафик при отключённом VPN — нули.
    expect(find.textContaining('0 B/s'), findsWidgets);
  });
}
