import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/ui/settings/gstatic_ping_section.dart';
import '../../app/app_controller_test.dart' show FakeTunnel, FakePlatformInfo;

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

AppController _build() => AppController(
      subscription:
          SubscriptionService(fetcher: (_) async => FetchResult('', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      resolveHost: (_) async => '9.9.9.9',
      gstaticProbe: (url, port, {timeout = const Duration(seconds: 3)}) async =>
          null,
    );

void main() {
  testWidgets('переключатель выключает пинг', (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, __) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    expect(c.settings.gstaticPingEnabled, isTrue);
    await t.tap(find.byType(ShadSwitch));
    await t.pump();

    expect(c.settings.gstaticPingEnabled, isFalse);

    // Таймер автообновления реальный — гасим до проверки pending-таймеров.
    c.dispose();
  });

  testWidgets('слайдер скрыт, когда пинг выключен', (t) async {
    final c = _build();
    await c.init();
    await c.updateSettings(c.settings.copyWith(gstaticPingEnabled: false));

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, __) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    expect(find.byType(ShadSlider), findsNothing);

    c.dispose();
  });

  testWidgets('слайдер отпущенный на новом значении сохраняет интервал',
      (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, __) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    final slider = t.widget<ShadSlider>(find.byType(ShadSlider));
    slider.onChangeEnd!(40);
    await t.pump();

    expect(c.settings.gstaticPingIntervalSeconds, 40);

    c.dispose();
  });
}
