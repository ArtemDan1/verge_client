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
}
