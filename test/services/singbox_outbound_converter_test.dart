import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/singbox_outbound_converter.dart';

void main() {
  test('hysteria → sing-box hysteria2', () {
    final out = xrayOutboundToSingbox({
      'protocol': 'hysteria',
      'settings': {'address': 'h.example', 'port': 443, 'version': 2},
      'streamSettings': {
        'network': 'hysteria',
        'security': 'tls',
        'hysteriaSettings': {'version': 2, 'auth': 'AUTH'},
        'tlsSettings': {'serverName': 'sni.example', 'alpn': ['h3']},
      },
    })!;
    expect(out['type'], 'hysteria2');
    expect(out['tag'], 'proxy');
    expect(out['server'], 'h.example');
    expect(out['password'], 'AUTH');
    expect(out['tls']['server_name'], 'sni.example');
  });

  test('неизвестный протокол → null', () {
    expect(xrayOutboundToSingbox({'protocol': 'wireguard'}), isNull);
  });
}
