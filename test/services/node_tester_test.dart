import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/node_tester.dart';
import 'package:singbox_client/services/ping_service.dart';

NodeConfig _node(String name) => NodeConfig(
      name: name,
      protocol: NodeProtocol.vless,
      host: '$name.example.com',
      port: 443,
      params: const {'id': '00000000-0000-0000-0000-000000000000'},
    );

/// PingService с заранее заданными ответами по имени хоста.
PingService _pingWith(Map<String, int?> latencyByHost) => PingService(
      connect: (host, port, {timeout}) async {
        final ms = latencyByHost[host];
        if (ms == null) throw const SocketException('dead');
        return _FakeSocket();
      },
    );

class _FakeSocket extends Fake implements Socket {
  @override
  void destroy() {}
}

void main() {
  test('мёртвые по TCP ноды не доходят до HTTP-фазы', () async {
    final probed = <int>[];
    final tester = NodeTester(
      ping: _pingWith({'a.example.com': 10}),
      startSingbox: (_) async {},
      stopSingbox: () async {},
      startXray: (_) async {},
      stopXray: () async {},
      pickPort: () async => 9000 + probed.length,
      probe: (url, port, timeout) async {
        probed.add(port);
        return 42;
      },
    );

    final res = await tester.test([_node('a'), _node('b')],
        url: 'https://example.com');

    expect(probed.length, 1, reason: 'b мертва по TCP — её не проверяем');
    expect(res.first.node.name, 'a');
    expect(res.first.latencyMs, 42);
    expect(res.last.node.name, 'b');
    expect(res.last.latencyMs, isNull);
  });

  test('побеждает минимальная HTTP-задержка, а не минимальный TCP', () async {
    final byPort = <int, int>{};
    var next = 9000;
    final tester = NodeTester(
      ping: _pingWith({'a.example.com': 10, 'b.example.com': 200}),
      startSingbox: (_) async {},
      stopSingbox: () async {},
      startXray: (_) async {},
      stopXray: () async {},
      pickPort: () async => next++,
      probe: (url, port, timeout) async => byPort[port]!,
    );
    // Порты выдаются в порядке нод: сначала a, потом b.
    byPort[9000] = 300;
    byPort[9001] = 50;

    final res = await tester.test([_node('a'), _node('b')],
        url: 'https://example.com');

    expect(res.first.node.name, 'b');
    expect(res.first.latencyMs, 50);
  });

  test('в HTTP-фазу идут только 5 лучших по TCP', () async {
    var probes = 0;
    var next = 9000;
    final nodes = [for (var i = 0; i < 8; i++) _node('n$i')];
    final tester = NodeTester(
      ping: _pingWith({for (var i = 0; i < 8; i++) 'n$i.example.com': i}),
      startSingbox: (_) async {},
      stopSingbox: () async {},
      startXray: (_) async {},
      stopXray: () async {},
      pickPort: () async => next++,
      probe: (url, port, timeout) async {
        probes++;
        return 10;
      },
    );

    await tester.test(nodes, url: 'https://example.com');

    expect(probes, 5);
  });

  test('процесс останавливается, даже если проба бросила', () async {
    var stopped = 0;
    final tester = NodeTester(
      ping: _pingWith({'a.example.com': 10}),
      startSingbox: (_) async {},
      stopSingbox: () async => stopped++,
      startXray: (_) async {},
      stopXray: () async => stopped++,
      pickPort: () async => 9000,
      probe: (url, port, timeout) async => throw StateError('boom'),
    );

    final res = await tester.test([_node('a')], url: 'https://example.com');

    expect(stopped, greaterThanOrEqualTo(1));
    expect(res.first.latencyMs, isNull, reason: 'исключение = провал ноды');
  });

  test('дубликаты нод получают каждая свой порт и свой результат', () async {
    // NodeConfig сравнивается по значению: две одинаковые ноды в подписке не
    // должны схлопнуться в один ключ — иначе они делили бы порт и тестовый
    // процесс не забиндился бы.
    final ports = <int>[];
    var next = 9000;
    final tester = NodeTester(
      ping: _pingWith({'a.example.com': 10}),
      startSingbox: (cfg) async {
        for (final i in cfg['inbounds'] as List) {
          ports.add((i as Map)['listen_port'] as int);
        }
      },
      stopSingbox: () async {},
      startXray: (_) async {},
      stopXray: () async {},
      pickPort: () async => next++,
      probe: (url, port, timeout) async => port,
    );

    final res = await tester.test([_node('a'), _node('a')],
        url: 'https://example.com');

    expect(ports, [9000, 9001], reason: 'порт на каждую ноду свой');
    expect(res.map((r) => r.latencyMs), [9000, 9001]);
  });

  test('check возвращает false, когда нода не отвечает по HTTP', () async {
    final tester = NodeTester(
      ping: _pingWith({'a.example.com': 10}),
      startSingbox: (_) async {},
      stopSingbox: () async {},
      startXray: (_) async {},
      stopXray: () async {},
      pickPort: () async => 9000,
      probe: (url, port, timeout) async => null,
    );

    expect(await tester.check(_node('a'), url: 'https://example.com'), isFalse);
  });

  test('bypassTunnel прокидывается в TCP-префильтр', () async {
    var bypassCalls = 0;
    var plainCalls = 0;
    NodeTester tester() => NodeTester(
          ping: PingService(
            connect: (host, port, {timeout}) async {
              plainCalls++;
              return _FakeSocket();
            },
            bypassPing: (host, port,
                {timeout = const Duration(seconds: 3)}) async {
              bypassCalls++;
              return 10;
            },
          ),
          startSingbox: (_) async {},
          stopSingbox: () async {},
          startXray: (_) async {},
          stopXray: () async {},
          pickPort: () async => 9000,
          probe: (url, port, timeout) async => 42,
        );

    await tester()
        .test([_node('a')], url: 'https://example.com', bypassTunnel: true);
    expect(bypassCalls, 1);
    expect(plainCalls, 0);

    await tester().test([_node('a')], url: 'https://example.com');
    expect(bypassCalls, 1, reason: 'без флага меряем обычным сокетом');
    expect(plainCalls, 1);
  });
}
