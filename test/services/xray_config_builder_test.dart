import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/xray_config_builder.dart';

void main() {
  const node = NodeConfig(
    name: 'A', protocol: NodeProtocol.hysteria2, host: 'h.example', port: 443,
    params: {'password': 'AUTH'},
  );

  test('socks-inbound на loopback с включённым UDP', () {
    final cfg = buildXrayConfig(node, socksPort: 11080)!;
    final inbound = (cfg['inbounds'] as List).single as Map;
    expect(inbound['listen'], '127.0.0.1');
    expect(inbound['port'], 11080);
    expect(inbound['protocol'], 'socks');
    expect(inbound['settings']['udp'], true);
    expect(inbound['settings']['auth'], 'noauth');
  });

  test('ровно один outbound с тегом proxy, без routing и sniffing', () {
    final cfg = buildXrayConfig(node, socksPort: 11080)!;
    final outbounds = cfg['outbounds'] as List;
    expect(outbounds, hasLength(1));
    expect((outbounds.single as Map)['tag'], 'proxy');
    // Роутинг и sniff — работа sing-box; у Xray один outbound и ноль правил.
    expect(cfg.containsKey('routing'), isFalse);
    expect((cfg['inbounds'] as List).single, isNot(contains('sniffing')));
  });

  test('нода без Xray-формы → null', () {
    const naive = NodeConfig(
      name: 'B', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    expect(buildXrayConfig(naive, socksPort: 11080), isNull);
  });
}
