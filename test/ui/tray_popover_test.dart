import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/app/tray_popover_controller.dart';
import 'package:singbox_client/app/window_control_channel.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/ui/tray_popover.dart';
import '../app/app_controller_test.dart' show FakeTunnel, FakePlatformInfo;

const _subs = 'vless://u@nl.example:443#%F0%9F%87%B3%F0%9F%87%B1%20Amsterdam\n'
    'vless://u@de.example:443#%F0%9F%87%A9%F0%9F%87%AA%20Frankfurt';

void main() {
  const channel = MethodChannel('window/control');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  Future<(AppController, TrayPopoverController)> pump(
      WidgetTester tester) async {
    tester.view.physicalSize = const Size(340, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final c = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult(_subs, const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      timerFactory: (d, cb) => Timer(Duration.zero, () {}),
    );
    await c.init();
    await c.addProfile('Nebula', 'https://sub.example');
    await c.selectNode(c.profiles.single.id, 0);
    final popover = TrayPopoverController(WindowControlChannel(channel),
        waitForFrame: () async {});
    await popover.toggle(TrayPopover.heightFor(c));
    await tester.pumpWidget(
        ShadApp(home: TrayPopover(controller: c, popover: popover)));
    await tester.pump();
    return (c, popover);
  }

  testWidgets('показывает статус и сервера активного профиля без флагов',
      (tester) async {
    final (c, _) = await pump(tester);
    expect(find.text('Не подключено'), findsOneWidget);
    expect(find.text('Сервер · Nebula'), findsOneWidget);
    // Флаг из имени ноды превращён в код страны.
    expect(find.text('NL'), findsOneWidget);
    expect(find.text('Amsterdam'), findsOneWidget);
    c.dispose();
  });

  testWidgets('клик по серверу выбирает его', (tester) async {
    final (c, _) = await pump(tester);
    await tester.tap(find.text('Frankfurt'));
    await tester.pump();
    expect(c.profiles.single.selectedNodeIndex, 1);
    c.dispose();
  });

  testWidgets('«Открыть Verge» закрывает мини-окно и открывает главное',
      (tester) async {
    final (c, popover) = await pump(tester);
    await tester.tap(find.text('Открыть Verge'));
    await tester.pump();
    expect(popover.isOpen, isFalse);
    expect(calls.last.method, 'hidePopover');
    expect(calls.last.arguments, {'openMain': true});
    c.dispose();
  });

  test('высота окна растёт с числом серверов до предела', () {
    // Без профиля — компактное окно с подсказкой.
    final empty = AppController(
      subscription: SubscriptionService(
          fetcher: (_) async => FetchResult('', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
    );
    expect(TrayPopover.heightFor(empty), lessThan(300));
  });
}
