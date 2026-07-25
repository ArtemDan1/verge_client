import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/connection_info.dart';

Map<String, dynamic> _conn({
  List<String> chains = const ['proxy', 'Автовыбор'],
  String rule = 'rule_set',
  String host = 'claude.ai',
  String processPath = '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
}) =>
    {
      'id': 'abc-1',
      'start': '2026-07-25T10:00:00.000Z',
      'upload': 67174,
      'download': 25190,
      'chains': chains,
      'rule': rule,
      'rulePayload': 'geosite-gfw',
      'metadata': {
        'network': 'tcp',
        'type': 'tls',
        'host': host,
        'destinationIP': '160.79.104.10',
        'destinationPort': '443',
        'sourceIP': '10.20.0.1',
        'sourcePort': '62836',
        'processPath': processPath,
      },
    };

void main() {
  group('ConnectionInfo.fromJson', () {
    test('разбирает основные поля', () {
      final c = ConnectionInfo.fromJson(_conn());
      expect(c.id, 'abc-1');
      expect(c.upload, 67174);
      expect(c.download, 25190);
      expect(c.network, 'tcp');
      expect(c.sniffedType, 'tls');
      expect(c.destinationPort, 443);
      expect(c.sourcePort, 62836);
      expect(c.title, 'claude.ai:443');
      expect(c.source, '10.20.0.1:62836');
      expect(c.appName, 'Brave Browser');
      expect(c.chainLabel, 'Автовыбор → proxy');
    });

    test('пустой host — заголовок из IP', () {
      final c = ConnectionInfo.fromJson(_conn(host: ''));
      expect(c.title, '160.79.104.10:443');
    });

    test('пустой processPath даёт appName == null', () {
      final c = ConnectionInfo.fromJson(_conn(processPath: ''));
      expect(c.appName, isNull);
    });

    test('durationAt считает от start', () {
      final c = ConnectionInfo.fromJson(_conn());
      final now = DateTime.parse('2026-07-25T10:13:04.000Z');
      expect(c.durationAt(now), const Duration(minutes: 13, seconds: 4));
    });
  });

  group('outboundKind', () {
    test('direct по последнему элементу chains', () {
      expect(ConnectionInfo.fromJson(_conn(chains: ['direct'])).outboundKind,
          OutboundKind.direct);
    });
    test('block по тегу block или reject', () {
      expect(ConnectionInfo.fromJson(_conn(chains: ['block'])).outboundKind,
          OutboundKind.block);
      expect(ConnectionInfo.fromJson(_conn(chains: ['reject'])).outboundKind,
          OutboundKind.block);
    });
    test('всё остальное — proxy', () {
      expect(
        ConnectionInfo.fromJson(_conn(chains: ['proxy', 'Anton-565GB'])).outboundKind,
        OutboundKind.proxy,
      );
    });
    test('пустой chains — падаем на rule', () {
      final json = _conn(chains: const [], rule: 'direct');
      expect(ConnectionInfo.fromJson(json).outboundKind, OutboundKind.direct);
    });
  });

  group('parseConnections / TrafficStats', () {
    final snapshot = {
      'downloadTotal': 2254857830,
      'uploadTotal': 356515840,
      'connections': [_conn(), _conn()],
    };

    test('parseConnections читает список', () {
      expect(parseConnections(snapshot).length, 2);
    });

    test('снапшот без connections даёт пустой список', () {
      expect(parseConnections({'connections': null}), isEmpty);
    });

    test('суммы берутся из снапшота, скорости сохраняются', () {
      const prev = TrafficStats(upSpeed: 10, downSpeed: 20, upTotal: 1, downTotal: 2);
      final t = TrafficStats.fromConnectionsSnapshot(snapshot, prev);
      expect(t.upTotal, 356515840);
      expect(t.downTotal, 2254857830);
      expect(t.upSpeed, 10);
      expect(t.downSpeed, 20);
    });

    test('скорости берутся из /traffic, суммы сохраняются', () {
      const prev = TrafficStats(upSpeed: 0, downSpeed: 0, upTotal: 5, downTotal: 6);
      final t = TrafficStats.fromTraffic({'up': 1258291, 'down': 8808038}, prev);
      expect(t.upSpeed, 1258291);
      expect(t.downSpeed, 8808038);
      expect(t.upTotal, 5);
      expect(t.downTotal, 6);
    });
  });
}
