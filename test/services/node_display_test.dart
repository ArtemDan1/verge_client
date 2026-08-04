import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/node_display.dart';

void main() {
  test('vless + reality + xhttp — все сегменты в строке', () {
    final n = NodeConfig(
      name: 'VPN | Франция', protocol: NodeProtocol.vless,
      host: 'cloud-most-2.harknmav.fun', port: 6001, params: const {},
      rawSchema: RawSchema.xray,
      rawOutbound: const {
        'protocol': 'vless',
        'streamSettings': {'network': 'xhttp', 'security': 'reality'},
      },
    );
    expect(nodeSubtitle(n),
        'vless · reality · xhttp · cloud-most-2.harknmav.fun:6001');
  });

  test('без security и транспорта остаются протокол и адрес', () {
    const n = NodeConfig(
      name: 'n', protocol: NodeProtocol.hysteria2,
      host: 'example.com', port: 443, params: {},
    );
    expect(nodeSubtitle(n), 'hysteria2 · example.com:443');
  });

  test('trojan с tls, но без транспорта', () {
    final n = NodeConfig(
      name: 'n', protocol: NodeProtocol.vless, host: 'example.com', port: 443,
      params: const {}, rawSchema: RawSchema.singbox,
      rawOutbound: const {'type': 'trojan', 'tls': {'enabled': true}},
    );
    expect(nodeSubtitle(n), 'trojan · tls · example.com:443');
  });
}
