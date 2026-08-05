import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/auto_select_settings.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/auto_select_dialog.dart';

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

Future<AppController> buildController() async {
  final c = AppController(
    subscription: SubscriptionService(
        fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
    builder: const ConfigBuilder(),
    proxyTunnel: FakeTunnel(),
    tunTunnel: FakeTunnel(),
    repo: InMemoryStateRepository(),
    platform: FakePlatformInfo(),
    timerFactory: (duration, callback) => Timer(Duration.zero, () {}),
  );
  await c.init();
  await c.addProfile('Sub', 'https://example.com/sub');
  return c;
}

Future<void> pumpAutoSelectDialog(WidgetTester tester, AppController c) async {
  await tester.pumpWidget(
    ShadApp(
      home: Builder(
        builder: (ctx) => ShadButton(
          onPressed: () => showAutoSelectDialog(ctx, c),
          child: const Text('открыть'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('сохранение пишет настройки, интервал зажимается', (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);
    final profileId = c.profiles.single.id;
    await pumpAutoSelectDialog(tester, c);

    await tester.tap(find.byType(ShadSwitch));
    await tester.pump();
    await tester.tap(find.text(c.profiles.single.name));
    await tester.pump();
    // Второй ShadInput — интервал (первый — адрес).
    await tester.enterText(find.byType(ShadInput).at(1), '5');
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(c.autoSelect.enabled, isTrue);
    expect(c.autoSelect.profileIds, {profileId});
    expect(c.autoSelect.healthCheckIntervalSeconds, 15);
  });

  testWidgets('пустой адрес заменяется дефолтом', (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);
    await pumpAutoSelectDialog(tester, c);

    await tester.enterText(find.byType(ShadInput).first, '');
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(c.autoSelect.testUrl, AutoSelectSettings.defaultTestUrl);
  });
}
