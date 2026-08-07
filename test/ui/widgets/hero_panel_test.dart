import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/ping_service.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/widgets/hero_panel.dart';
import '../../app/app_controller_test.dart' show FakeTunnel, FakePlatformInfo;

// В тестах рендерится шрифт-заглушка Ahem с другими метриками: при боевом
// масштабе текста табы на 8px переполняют свою фиксированную высоту.
Widget _wrap(Widget child) => ShadApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(0.85)),
      child: Scaffold(body: Center(child: child)),
    ));

void main() {
  testWidgets(
      'после подключения показывает бейдж пинга ноды справа от таймера',
      (t) async {
    final proxy = FakeTunnel();
    final controller = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: proxy,
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
          10,
      pingService: PingService(
        connect: (host, port, {timeout}) async {
          throw const SocketException('unused, only latency matters');
        },
      ),
    );
    await controller.init();
    await controller.addProfile('Sub', 'https://x');
    await controller.selectNode(controller.profiles.first.id, 0);

    await t.pumpWidget(_wrap(HeroPanel(controller: controller)));
    await t.pump();

    // Отключено — бейджа нет.
    expect(find.textContaining('мс'), findsNothing);

    proxy.emit(TunnelStatus.connected);
    await t.pump();
    await t.pump(); // даём завершиться refreshHeroPing()

    // Фейковый connect всегда падает без osError -> PingService трактует это
    // как таймаут; чип должен показать состояние ноды, а не "10 мс" gstatic.
    expect(find.text('таймаут'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('тап по бейджу вызывает ручной перепинг ноды и gstatic',
      (t) async {
    var gstaticCalls = 0;
    var nodeCalls = 0;
    final proxy = FakeTunnel();
    final controller = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: proxy,
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async {
        gstaticCalls++;
        return 10;
      },
      pingService: PingService(
        connect: (host, port, {timeout}) async {
          nodeCalls++;
          throw const SocketException('unused');
        },
      ),
    );
    await controller.init();
    await controller.addProfile('Sub', 'https://x');
    await controller.selectNode(controller.profiles.first.id, 0);
    proxy.emit(TunnelStatus.connected);

    await t.pumpWidget(_wrap(HeroPanel(controller: controller)));
    await t.pump();
    await t.pump();
    gstaticCalls = 0;
    nodeCalls = 0;

    await t.tap(find.text('таймаут'));
    await t.pump();
    await t.pump();

    expect(gstaticCalls, 1);
    expect(nodeCalls, 1);

    controller.dispose();
  });

  testWidgets('в TUN показывает пинг ноды, замеренный мимо туннеля',
      (t) async {
    var bypassCalls = 0;
    var plainSocketCalls = 0;
    final tun = FakeTunnel();
    final controller = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('vless://u@h:443#A', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: tun,
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      // Интернет есть — значит на чипе должно быть число, а не «нет интернета».
      bypassProbe: (host, port, {timeout = const Duration(seconds: 3)}) async =>
          7,
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
          33,
      pingService: PingService(
        connect: (host, port, {timeout}) async {
          plainSocketCalls++;
          throw const SocketException('обычный сокет в TUN меряет туннель');
        },
        bypassPing: (host, port, {timeout = const Duration(seconds: 3)}) async {
          bypassCalls++;
          return 21;
        },
      ),
    );
    await controller.init();
    await controller.addProfile('Sub', 'https://x');
    await controller.selectNode(controller.profiles.first.id, 0);
    await controller.updateSettings(
        controller.settings.copyWith(tunnelMode: TunnelMode.tun));

    await t.pumpWidget(_wrap(HeroPanel(controller: controller)));
    await t.pump();

    tun.emit(TunnelStatus.connected);
    await t.pump();
    await t.pump();

    expect(find.text('21 мс'), findsOneWidget);
    expect(bypassCalls, greaterThanOrEqualTo(1));
    expect(plainSocketCalls, 0);

    controller.dispose();
  });
}
