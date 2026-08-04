import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/network_settings.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/config_builder.dart';

final testNode = NodeConfig(
  name: 'n', protocol: NodeProtocol.vless, host: 'srv.example', port: 443,
  params: const {'uuid': 'u1', 'security': 'reality', 'sni': 'a.example'},
);

void main() {
  test('ipv6Enabled убирает reject-правило и меняет стратегию DNS', () {
    final cfg = const ConfigBuilder(network: NetworkSettings(ipv6Enabled: true))
        .build(testNode, mode: TunnelMode.tun, serverIp: '1.2.3.4');
    final rules = (cfg['route'] as Map)['rules'] as List;
    expect(
      rules.any((r) => (r as Map)['ip_version'] == 6),
      isFalse,
    );
    expect((cfg['dns'] as Map)['strategy'], isNot('ipv4_only'));
  });

  test('кастомные параметры TUN попадают в inbound', () {
    final cfg = const ConfigBuilder(
      network: NetworkSettings(
        tunAddressV4: '10.20.0.1/30',
        tunMtu: 1500,
        tunStack: TunStack.system,
        tunStrictRoute: true,
        tunAutoRoute: false,
      ),
    ).build(testNode, mode: TunnelMode.tun, serverIp: '1.2.3.4');
    final tun = ((cfg['inbounds'] as List).first as Map);
    expect((tun['address'] as List).first, '10.20.0.1/30');
    expect(tun['mtu'], 1500);
    expect(tun['stack'], 'system');
    expect(tun['strict_route'], isTrue);
    expect(tun['auto_route'], isFalse);
  });

  test('dnsHijack: false убирает правило перехвата', () {
    final cfg = const ConfigBuilder(network: NetworkSettings(dnsHijack: false))
        .build(testNode, mode: TunnelMode.tun, serverIp: '1.2.3.4');
    final rules = (cfg['route'] as Map)['rules'] as List;
    expect(
      rules.any((r) => (r as Map)['action'] == 'hijack-dns'),
      isFalse,
    );
  });

  test('кастомные DNS-серверы попадают в конфиг', () {
    final cfg = const ConfigBuilder(
      network: NetworkSettings(
        proxyDnsServer: '9.9.9.9',
        directDnsServer: '8.8.8.8',
      ),
    ).build(testNode, mode: TunnelMode.tun, serverIp: '1.2.3.4');
    final servers = (cfg['dns'] as Map)['servers'] as List;
    expect((servers.first as Map)['server'], '9.9.9.9');
    expect((servers[1] as Map)['server'], '8.8.8.8');
  });

  // Сторож: sing-box 1.13 отвергает и legacy-секцию dns.fakeip, и поле
  // dns.ttl, которого в схеме нет вовсе. С любым из них движок падает на
  // старте, поэтому в конфиге их не должно быть ни при каких настройках.
  test('конфиг не содержит dns.fakeip и dns.ttl', () {
    for (final mode in TunnelMode.values) {
      final cfg = const ConfigBuilder()
          .build(testNode, mode: mode, serverIp: '1.2.3.4');
      final dns = cfg['dns'] as Map;
      expect(dns.containsKey('fakeip'), isFalse, reason: 'режим $mode');
      expect(dns.containsKey('ttl'), isFalse, reason: 'режим $mode');
    }
  });

  test('tlsSkipCertVerify выставляет insecure в sing-box outbound', () {
    final cfg = const ConfigBuilder(
      network: NetworkSettings(tlsSkipCertVerify: true),
    ).build(testNode);
    final out = (cfg['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['tag'] == 'proxy');
    expect((out['tls'] as Map)['insecure'], isTrue);
  });

  test('без tlsSkipCertVerify ключ insecure отсутствует', () {
    final cfg = const ConfigBuilder().build(testNode);
    final out = (cfg['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['tag'] == 'proxy');
    expect((out['tls'] as Map?)?.containsKey('insecure') ?? false, isFalse);
  });

  test('tlsFragmentEnabled выставляет fragment и fragment_fallback_delay', () {
    final cfg = const ConfigBuilder(
      network: NetworkSettings(
        tlsFragmentEnabled: true,
        tlsFragmentFallbackDelay: '1s',
      ),
    ).build(testNode);
    final out = (cfg['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['tag'] == 'proxy');
    final tls = out['tls'] as Map;
    expect(tls['fragment'], isTrue);
    expect(tls['fragment_fallback_delay'], '1s');
  });

  test('tlsRecordFragment выставляет record_fragment', () {
    final cfg = const ConfigBuilder(
      network: NetworkSettings(tlsRecordFragment: true),
    ).build(testNode);
    final out = (cfg['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['tag'] == 'proxy');
    expect((out['tls'] as Map)['record_fragment'], isTrue);
  });

  test('без tlsFragmentEnabled ключ fragment отсутствует', () {
    final cfg = const ConfigBuilder().build(testNode);
    final out = (cfg['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['tag'] == 'proxy');
    expect((out['tls'] as Map?)?.containsKey('fragment') ?? false, isFalse);
  });
}
