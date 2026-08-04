import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/platform/platform_info.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';
import 'package:singbox_client/ui/edit_node_dialog.dart';

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

/// Xray-подписка из одной vless-ноды: подходит и для формы, и для JSON.
const _xraySub = '''
[
  {
    "remarks": "Нода",
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "old.example",
              "port": 443,
              "users": [{"id": "uuid-1"}]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "tls",
          "tlsSettings": {"serverName": "old.sni"}
        }
      }
    ]
  }
]
''';

Future<AppController> buildController() async {
  final c = AppController(
    subscription: SubscriptionService(
        fetcher: (_) async => FetchResult(_xraySub, const {})),
    builder: const ConfigBuilder(),
    proxyTunnel: FakeTunnel(),
    tunTunnel: FakeTunnel(),
    repo: InMemoryStateRepository(),
    platform: FakePlatformInfo(),
  );
  await c.init();
  await c.addProfile('Sub', 'https://example.com/sub');
  return c;
}

/// Открывает диалог редактирования первой ноды профиля.
Future<NodeConfig> pumpDialog(WidgetTester tester, AppController c) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final profile = c.profiles.single;
  final node = profile.nodes.first;

  await tester.pumpWidget(ShadApp(
    home: Builder(
      builder: (ctx) => ShadButton(
        onPressed: () =>
            showEditNodeDialog(ctx, c, profile.id, 0, node),
        child: const Text('открыть'),
      ),
    ),
  ));
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
  return node;
}

/// Единственное многострочное поле в диалоге — редактор JSON.
Finder jsonField() => find.byWidgetPredicate(
    (w) => w is ShadInput && (w.maxLines ?? 1) > 1);

void main() {
  testWidgets('правка на вкладке JSON не теряется при сохранении из формы',
      (tester) async {
    final c = await buildController();
    await pumpDialog(tester, c);

    // Уходим в JSON и дописываем поле, которого в форме нет.
    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();

    final raw = jsonDecode(tester.widget<ShadInput>(jsonField()).controller!.text)
        as Map<String, dynamic>;
    raw['sockopt'] = {'tcpFastOpen': true};
    await tester.enterText(jsonField(), jsonEncode(raw));
    await tester.pumpAndSettle();

    // Возвращаемся в форму и сохраняем оттуда.
    await tester.tap(find.text('Форма'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final saved = c.profiles.single.nodes.first;
    expect(saved.rawOutbound!['sockopt'], {'tcpFastOpen': true},
        reason: 'поле из JSON должно пережить сохранение через форму');
  });

  testWidgets('правка формы видна на вкладке JSON и переживает возврат',
      (tester) async {
    final c = await buildController();
    await pumpDialog(tester, c);

    await tester.enterText(find.byType(ShadInput).at(1), 'new.example');
    await tester.pumpAndSettle();

    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();
    expect(tester.widget<ShadInput>(jsonField()).controller!.text,
        contains('new.example'));

    await tester.tap(find.text('Форма'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(c.profiles.single.nodes.first.host, 'new.example');
  });

  testWidgets('битый JSON блокирует сохранение и показывает ошибку',
      (tester) async {
    final c = await buildController();
    final before = await pumpDialog(tester, c);

    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();
    await tester.enterText(jsonField(), '{ это не json');
    await tester.pumpAndSettle();

    // Переключение на форму не проходит: остаёмся в JSON с ошибкой.
    await tester.tap(find.text('Форма'));
    await tester.pumpAndSettle();
    expect(jsonField(), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(c.profiles.single.nodes.first.rawOutbound,
        equals(before.rawOutbound));
  });
}
