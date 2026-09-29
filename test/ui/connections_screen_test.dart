import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/app/app_controller.dart';
import 'package:singbox_client/services/clash_api_client.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/subscription_service.dart';
import 'package:singbox_client/storage/state_repository.dart';
import 'package:singbox_client/models/connection_info.dart';
import 'package:singbox_client/ui/connections_screen.dart';
import '../app/app_controller_test.dart' show FakeTunnel, FakePlatformInfo;

ConnectionInfo _c({
  String id = 'a',
  String host = 'claude.ai',
  String ip = '1.2.3.4',
  String process = '/Applications/Brave.app/Contents/MacOS/Brave',
  List<String> chains = const ['proxy'],
}) =>
    ConnectionInfo(
      id: id,
      start: DateTime.utc(2026, 7, 25, 10),
      upload: 1,
      download: 2,
      network: 'tcp',
      sniffedType: 'tls',
      host: host,
      destinationIP: ip,
      destinationPort: 443,
      sourceIP: '10.20.0.1',
      sourcePort: 5000,
      processPath: process,
      chains: chains,
      rule: 'final',
      rulePayload: '',
    );

void main() {
  drawerTests();

  final all = [
    _c(id: 'a', host: 'claude.ai'),
    _c(id: 'b', host: 'mail.ru', chains: const ['direct']),
    _c(id: 'c', host: 'ads.example', chains: const ['block'], process: '/usr/bin/curl'),
  ];

  test('пустой запрос и пустые фильтры отдают всё', () {
    expect(filterConnections(all, query: '', kinds: {}).length, 3);
  });

  test('поиск по домену без учёта регистра', () {
    final r = filterConnections(all, query: 'CLAUDE', kinds: {});
    expect(r.map((e) => e.id), ['a']);
  });

  test('поиск по имени приложения', () {
    final r = filterConnections(all, query: 'curl', kinds: {});
    expect(r.map((e) => e.id), ['c']);
  });

  test('поиск по IP', () {
    expect(filterConnections(all, query: '1.2.3.4', kinds: {}).length, 3);
  });

  test('фильтр по виду аутбаунда', () {
    final r = filterConnections(all, query: '', kinds: {OutboundKind.block});
    expect(r.map((e) => e.id), ['c']);
  });

  test('фильтр и поиск комбинируются', () {
    final r =
        filterConnections(all, query: 'mail', kinds: {OutboundKind.direct});
    expect(r.map((e) => e.id), ['b']);
    expect(filterConnections(all, query: 'mail', kinds: {OutboundKind.proxy}),
        isEmpty);
  });
}

/// Clash API с подставным списком соединений.
class _FakeClash extends ClashApiClient {
  final list = ValueNotifier<List<ConnectionInfo>>(const []);
  @override
  ValueListenable<List<ConnectionInfo>> get connections => list;
}

void drawerTests() {
  testWidgets('детали соединения — выдвижная панель, а не на весь экран',
      (tester) async {
    tester.view.physicalSize = const Size(1060, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final clash = _FakeClash();
    final c = AppController(
      subscription:
          SubscriptionService(fetcher: (_) async => FetchResult('', const {})),
      builder: const ConfigBuilder(),
      proxyTunnel: FakeTunnel(),
      tunTunnel: FakeTunnel(),
      repo: InMemoryStateRepository(),
      platform: FakePlatformInfo(),
      clashApi: clash,
      timerFactory: (d, cb) => Timer(Duration.zero, () {}),
    );
    await c.init();
    clash.list.value = [_c(id: 'a', host: 'claude.ai')];
    await tester.pumpWidget(
        ShadApp(home: Scaffold(body: ConnectionsScreen(controller: c))));
    await tester.pump();

    await tester.tap(find.textContaining('claude.ai').first);
    await tester.pumpAndSettle();

    // Панель — фиксированной ширины у правого края.
    final panel = find.ancestor(
        of: find.text('Отправлено'), matching: find.byType(Container));
    expect(tester.getSize(panel.last).width, 380);
    expect(find.text('Путь процесса'), findsOneWidget);

    // Соединение закрылось — панель остаётся и помечает это.
    clash.list.value = const [];
    await tester.pump();
    expect(find.text('соединение закрыто'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    expect(find.text('Путь процесса'), findsNothing);
    c.dispose();
  });
}
