import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/routing_screen.dart';

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
      subscription: SubscriptionService(fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
    );

void main() {
  testWidgets('список профилей; пресеты с замком; добавление нового',
      (tester) async {
    final c = buildController();
    await c.init();
    await tester.pumpWidget(ShadApp(home: RoutingScreen(controller: c)));
    await tester.pumpAndSettle();

    expect(find.text('Всё через прокси'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsWidgets);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(c.routingProfiles.where((p) => !p.isBuiltIn), isNotEmpty);
    // Реальный периодический таймер автообновления должен быть отменён
    // до конца теста — иначе flutter_test падает на pending timer.
    c.dispose();
  });

  testWidgets('клон пресета создаёт редактируемую копию', (tester) async {
    final c = buildController();
    await c.init();
    await tester.pumpWidget(ShadApp(home: RoutingScreen(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.copy).first);
    await tester.pumpAndSettle();
    expect(c.routingProfiles.where((p) => !p.isBuiltIn), isNotEmpty);
    c.dispose();
  });
}
