import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';

void main() {
  test('NodeConfig равенство по значению', () {
    const a = NodeConfig(name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {'uuid': 'u'});
    const b = NodeConfig(name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {'uuid': 'u'});
    expect(a, equals(b));
  });

  test('NodeConfig JSON round-trip с rawOutbound', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u'}, rawOutbound: {'type': 'naive', 'password': 'p'},
    );
    final restored = NodeConfig.fromJson(node.toJson());
    expect(restored, equals(node));
    expect(restored.rawOutbound, {'type': 'naive', 'password': 'p'});
  });

  test('rawSchema по умолчанию singbox и переживает сериализацию', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
    );
    expect(node.rawSchema, RawSchema.singbox);
    expect(NodeConfig.fromJson(node.toJson()).rawSchema, RawSchema.singbox);
  });

  test('миграция: старый persisted-state без rawSchema читается как singbox', () {
    // В старом формате rawOutbound хранил УЖЕ сконвертированный sing-box-outbound,
    // поэтому отсутствие поля должно означать именно singbox — иначе конфиги
    // существующих пользователей сломались бы после обновления.
    final node = NodeConfig.fromJson({
      'name': 'A', 'protocol': 'vless', 'host': 'h', 'port': 443,
      'params': <String, String>{},
      'rawOutbound': {'type': 'vless', 'tag': 'proxy', 'server': 'h'},
    });
    expect(node.rawSchema, RawSchema.singbox);
  });

  test('transport: xhttp из params share-ссылки', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'type': 'xhttp'},
    );
    expect(node.transport, 'xhttp');
  });

  test('transport: xhttp из Xray-outbound', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
      rawSchema: RawSchema.xray,
      rawOutbound: {'streamSettings': {'network': 'xhttp'}},
    );
    expect(node.transport, 'xhttp');
  });

  test('transport: ws из sing-box-outbound', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
      rawOutbound: {'transport': {'type': 'ws'}},
    );
    expect(node.transport, 'ws');
  });

  group('геттеры отображения', () {
    NodeConfig xrayNode(Map<String, dynamic> outbound) => NodeConfig(
          name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443,
          params: const {}, rawSchema: RawSchema.xray, rawOutbound: outbound,
        );

    NodeConfig singboxNode(Map<String, dynamic> outbound) => NodeConfig(
          name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443,
          params: const {}, rawSchema: RawSchema.singbox, rawOutbound: outbound,
        );

    test('xray: протокол, reality и xhttp читаются из outbound', () {
      final n = xrayNode({
        'protocol': 'vless',
        'streamSettings': {'network': 'xhttp', 'security': 'reality'},
      });
      expect(n.displayProtocol, 'vless');
      expect(n.security, 'reality');
      expect(n.transport, 'xhttp');
    });

    test('xray: trojan не выдаёт себя за vless', () {
      final n = xrayNode({
        'protocol': 'trojan',
        'streamSettings': {'network': 'ws', 'security': 'tls'},
      });
      expect(n.displayProtocol, 'trojan');
      expect(n.security, 'tls');
      expect(n.transport, 'ws');
    });

    test('xray: shadowsocks сокращается до ss, hysteria до hysteria2', () {
      expect(xrayNode({'protocol': 'shadowsocks'}).displayProtocol, 'ss');
      expect(xrayNode({'protocol': 'hysteria'}).displayProtocol, 'hysteria2');
    });

    test('xray: security=none и network=tcp считаются отсутствием', () {
      final n = xrayNode({
        'protocol': 'vless',
        'streamSettings': {'network': 'tcp', 'security': 'none'},
      });
      expect(n.security, isNull);
      expect(n.transport, isNull);
    });

    test('sing-box: reality определяется по tls.reality.enabled', () {
      final n = singboxNode({
        'type': 'trojan',
        'tls': {'enabled': true, 'reality': {'enabled': true}},
        'transport': {'type': 'ws'},
      });
      expect(n.displayProtocol, 'trojan');
      expect(n.security, 'reality');
      expect(n.transport, 'ws');
    });

    test('sing-box: голый tls без reality', () {
      final n = singboxNode({'type': 'vless', 'tls': {'enabled': true}});
      expect(n.security, 'tls');
      expect(n.transport, isNull);
    });

    test('sing-box: tls.enabled=false — security нет', () {
      expect(singboxNode({'type': 'vmess', 'tls': {'enabled': false}}).security,
          isNull);
    });

    test('без rawOutbound берём enum и params', () {
      const n = NodeConfig(
        name: 'n', protocol: NodeProtocol.hysteria2, host: 'h', port: 443,
        params: {'security': 'reality', 'type': 'grpc'},
      );
      expect(n.displayProtocol, 'hysteria2');
      expect(n.security, 'reality');
      expect(n.transport, 'grpc');
    });

    test('без rawOutbound: security=none и type=tcp — пусто', () {
      const n = NodeConfig(
        name: 'n', protocol: NodeProtocol.vless, host: 'h', port: 443,
        params: {'security': 'none', 'type': 'tcp'},
      );
      expect(n.security, isNull);
      expect(n.transport, isNull);
    });
  });
}
