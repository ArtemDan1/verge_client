import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/node_editor.dart';

NodeConfig xrayVless() => NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'old.example', port: 443,
      params: const {}, rawSchema: RawSchema.xray,
      rawOutbound: const {
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': 'old.example',
              'port': 443,
              'users': [
                {'id': 'uuid-1', 'flow': 'xtls-rprx-vision'}
              ],
            }
          ],
        },
        'streamSettings': {
          'network': 'xhttp',
          'security': 'reality',
          'realitySettings': {
            'serverName': 'old.sni',
            'fingerprint': 'chrome',
            'publicKey': 'pbk-1',
            'shortId': 'sid-1',
          },
        },
      },
    );

NodeConfig singboxVless() => NodeConfig(
      name: 'B', protocol: NodeProtocol.vless, host: 'old.example', port: 443,
      params: const {}, rawSchema: RawSchema.singbox,
      rawOutbound: const {
        'type': 'vless',
        'server': 'old.example',
        'server_port': 443,
        'uuid': 'uuid-1',
        'tls': {
          'enabled': true,
          'server_name': 'old.sni',
          'utls': {'enabled': true, 'fingerprint': 'chrome'},
          'reality': {'enabled': true, 'public_key': 'pbk-1', 'short_id': 'sid-1'},
        },
        'transport': {'type': 'ws', 'path': '/p'},
      },
    );

void main() {
  group('draftFromNode', () {
    test('xray: читает адрес, uuid, flow и параметры reality', () {
      final d = draftFromNode(xrayVless());
      expect(d.host, 'old.example');
      expect(d.port, 443);
      expect(d.uuid, 'uuid-1');
      expect(d.flow, 'xtls-rprx-vision');
      expect(d.sni, 'old.sni');
      expect(d.fingerprint, 'chrome');
      expect(d.publicKey, 'pbk-1');
      expect(d.shortId, 'sid-1');
      expect(d.transport, 'xhttp');
      expect(d.security, 'reality');
    });

    test('sing-box: читает те же поля из своей схемы', () {
      final d = draftFromNode(singboxVless());
      expect(d.uuid, 'uuid-1');
      expect(d.sni, 'old.sni');
      expect(d.publicKey, 'pbk-1');
      expect(d.transport, 'ws');
      expect(d.security, 'reality');
      expect(d.path, '/p');
    });

    test('нода без rawOutbound читается из params', () {
      const n = NodeConfig(
        name: 'C', protocol: NodeProtocol.vless, host: 'h', port: 8443,
        params: {'uuid': 'u', 'sni': 's', 'pbk': 'p', 'sid': 'x', 'fp': 'chrome'},
      );
      final d = draftFromNode(n);
      expect(d.uuid, 'u');
      expect(d.sni, 's');
      expect(d.publicKey, 'p');
      expect(d.shortId, 'x');
      expect(d.fingerprint, 'chrome');
    });
  });

  group('applyDraft', () {
    test('xray: правки ложатся в vnext и streamSettings', () {
      final node = xrayVless();
      final d = draftFromNode(node)
        ..name = 'Новое имя'
        ..host = 'new.example'
        ..port = 8443
        ..uuid = 'uuid-2'
        ..sni = 'new.sni'
        ..transport = 'ws';
      final out = applyDraft(node, d);

      expect(out.name, 'Новое имя');
      expect(out.host, 'new.example');
      expect(out.port, 8443);
      final raw = out.rawOutbound!;
      final vnext = (raw['settings'] as Map)['vnext'] as List;
      expect((vnext.first as Map)['address'], 'new.example');
      expect((vnext.first as Map)['port'], 8443);
      expect((((vnext.first as Map)['users'] as List).first as Map)['id'],
          'uuid-2');
      final stream = raw['streamSettings'] as Map;
      expect(stream['network'], 'ws');
      expect((stream['realitySettings'] as Map)['serverName'], 'new.sni');
      // Поля, которых нет в форме, остаются нетронутыми.
      expect((stream['realitySettings'] as Map)['publicKey'], 'pbk-1');
    });

    test('sing-box: правки ложатся в server/tls/transport', () {
      final node = singboxVless();
      final d = draftFromNode(node)
        ..host = 'new.example'
        ..port = 8443
        ..uuid = 'uuid-2'
        ..sni = 'new.sni'
        ..transport = 'grpc';
      final out = applyDraft(node, d);

      final raw = out.rawOutbound!;
      expect(raw['server'], 'new.example');
      expect(raw['server_port'], 8443);
      expect(raw['uuid'], 'uuid-2');
      expect((raw['tls'] as Map)['server_name'], 'new.sni');
      expect((raw['transport'] as Map)['type'], 'grpc');
      // Не описанные формой поля не теряются.
      expect((raw['transport'] as Map)['path'], '/p');
    });

    test('нода без rawOutbound: правки ложатся в params', () {
      const n = NodeConfig(
        name: 'C', protocol: NodeProtocol.vless, host: 'h', port: 443,
        params: {'uuid': 'u', 'sni': 's'},
      );
      final d = draftFromNode(n)
        ..host = 'h2'
        ..sni = 's2';
      final out = applyDraft(n, d);
      expect(out.rawOutbound, isNull);
      expect(out.host, 'h2');
      expect(out.params['sni'], 's2');
      expect(out.params['uuid'], 'u');
    });

    test('исходная нода не мутируется', () {
      final node = xrayVless();
      final before = node.rawOutbound.toString();
      applyDraft(node, draftFromNode(node)..host = 'other');
      expect(node.rawOutbound.toString(), before);
    });

    test('пустое значение поля удаляет ключ, а не пишет пустую строку', () {
      final node = singboxVless();
      final out = applyDraft(node, draftFromNode(node)..sni = '');
      expect((out.rawOutbound!['tls'] as Map).containsKey('server_name'),
          isFalse);
    });
  });
}
