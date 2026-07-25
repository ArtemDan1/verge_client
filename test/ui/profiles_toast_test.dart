import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/platform/platform_info.dart';
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
  Future<String> appVersion() async => '1.0.0+1';
}

void main() {
  testWidgets('обновление подписок показывает shadcn-тост', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final c = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
    );
    await c.init();
    await c.addProfile('Sub', 'https://example.com/sub');

    await tester.pumpWidget(ShadApp(home: ProfilesScreen(controller: c)));
    await tester.pumpAndSettle();

    await c.refreshAllProfiles();
    // Несколько фреймов: post-frame callback → show → вставка тоста → анимация.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Подписки обновлены'), findsWidgets);
  });
}
