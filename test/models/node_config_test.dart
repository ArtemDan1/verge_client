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
}
