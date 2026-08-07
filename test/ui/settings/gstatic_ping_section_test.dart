import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputAction;
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
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    expect(c.settings.gstaticPingEnabled, isTrue);
    await t.tap(find.byType(ShadSwitch));
    await t.pump();

    expect(c.settings.gstaticPingEnabled, isFalse);

    // Таймер автообновления реальный — гасим до проверки pending-таймеров.
    c.dispose();
  });

  testWidgets('поля скрыты, когда пинг выключен', (t) async {
    final c = _build();
    await c.init();
    await c.updateSettings(c.settings.copyWith(gstaticPingEnabled: false));

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    expect(find.byKey(const Key('gstaticPingInterval')), findsNothing);
    expect(find.byKey(const Key('gstaticPingUrl')), findsNothing);

    c.dispose();
  });

  testWidgets('введённый интервал сохраняется по Enter', (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    await t.enterText(find.byKey(const Key('gstaticPingInterval')), '5');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();

    expect(c.settings.gstaticPingIntervalSeconds, 5);

    c.dispose();
  });

  testWidgets('интервал сохраняется при потере фокуса (уход на другой экран)',
      (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    await t.enterText(find.byKey(const Key('gstaticPingInterval')), '120');
    // Экран сменился — поле потеряло фокус, но не значение.
    await t.pumpWidget(_wrap(const SizedBox()));
    await t.pump();

    expect(c.settings.gstaticPingIntervalSeconds, 120);

    c.dispose();
  });

  testWidgets('интервал меньше минимума откатывается к сохранённому',
      (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    await t.enterText(find.byKey(const Key('gstaticPingInterval')), '0');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();

    expect(c.settings.gstaticPingIntervalSeconds, 60);

    c.dispose();
  });

  testWidgets('адрес проверки сохраняется, а мусор отбрасывается', (t) async {
    final c = _build();
    await c.init();

    await t.pumpWidget(_wrap(AnimatedBuilder(
      animation: c,
      builder: (_, _) => GstaticPingSection(controller: c),
    )));
    await t.pump();

    await t.enterText(
        find.byKey(const Key('gstaticPingUrl')), 'https://example.com/204');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(c.settings.gstaticPingUrl, 'https://example.com/204');

    await t.enterText(find.byKey(const Key('gstaticPingUrl')), 'не-адрес');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(c.settings.gstaticPingUrl, 'https://example.com/204');

    c.dispose();
  });
}
