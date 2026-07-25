import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/connection_info.dart';
import 'package:singbox_client/ui/connections_screen.dart';

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
