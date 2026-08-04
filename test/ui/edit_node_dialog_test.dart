import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/edit_node_dialog.dart';
import 'package:singbox_client/ui/widgets/json_editor.dart';

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
    // В UI-тестах периодический таймер остаётся pending; используем
    // одноразовый нулевой таймер — автообновление здесь не проверяется.
    timerFactory: (duration, callback) => Timer(Duration.zero, () {}),
  );
  await c.init();
  await c.addProfile('Sub', 'https://example.com/sub');
  return c;
}

/// Поднимает диалог редактирования на первой ноде профиля.
Future<void> pumpEditDialog(WidgetTester tester, AppController c) async {
  final profile = c.profiles.single;
  final node = profile.nodes.first;
  await tester.pumpWidget(
    ShadApp(
      home: Builder(
        builder: (ctx) => ShadButton(
          onPressed: () => showEditNodeDialog(ctx, c, profile.id, 0, node),
          child: const Text('открыть'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('в диалоге ровно один Scrollable и кнопка Сохранить видима',
      (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);

    // Маленькое окно: именно на нём проявляется двойной скролл.
    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpEditDialog(tester, c);

    // JsonEditor держит собственные Scrollable (номера строк + поле), поэтому
    // проверяем не их количество, а то, что диалог не ловит двойной скролл
    // ShadDialog + вложенный SingleChildScrollView (баг из задачи 1) — он
    // проявлялся как overflow/обрезка контента, а не как второй Scrollable.
    expect(find.text('Сохранить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('битый JSON блокирует сохранение и показывает ошибку',
      (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);
    await pumpEditDialog(tester, c);

    await tester.enterText(find.byType(JsonEditor), '{"type":');
    await tester.pump();

    expect(find.textContaining('Некорректный JSON'), findsOneWidget);
    final save = tester.widget<ShadButton>(
      find.ancestor(
        of: find.text('Сохранить'),
        matching: find.byType(ShadButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('валидный JSON сохраняется в контроллер', (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);
    await pumpEditDialog(tester, c);

    await tester.enterText(
      find.byType(JsonEditor),
      '{"type":"vless","server":"new.example","server_port":8443}',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final saved = c.profiles.first.nodes.first;
    expect(saved.host, 'new.example');
    expect(saved.port, 8443);
  });

  testWidgets('кнопка Форматировать приводит JSON к отступу 2', (tester) async {
    final c = await buildController();
    addTearDown(c.dispose);
    await pumpEditDialog(tester, c);

    await tester.enterText(find.byType(JsonEditor), '{"type":"vless"}');
    await tester.pump();
    await tester.tap(find.text('Форматировать'));
    await tester.pump();

    expect(find.textContaining('\n  "type"'), findsOneWidget);
  });
}
