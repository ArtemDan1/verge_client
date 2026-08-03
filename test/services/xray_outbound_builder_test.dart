import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/xray_outbound_builder.dart';

void main() {
  test('нода из Xray-подписки отдаётся как есть, с тегом proxy', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2, host: 'h', port: 443,
      params: {},
      rawSchema: RawSchema.xray,
      rawOutbound: {
        'protocol': 'hysteria', 'tag': 'whatever',
        'settings': {'address': 'h', 'port': 443, 'version': 2},
      },
    );
    final out = buildXrayOutbound(node)!;
    expect(out['protocol'], 'hysteria');
    expect(out['tag'], 'proxy');
    expect(out['settings']['address'], 'h');
  });

  test('hysteria2 из share-ссылки', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2,
      host: '1.2.3.4', port: 443,
      params: {'password': 'AUTH', 'sni': 'cdn.example'},
    );
    final out = buildXrayOutbound(node)!;
    expect(out['protocol'], 'hysteria');
    expect(out['settings'], {'address': '1.2.3.4', 'port': 443, 'version': 2});
    final stream = out['streamSettings'] as Map<String, dynamic>;
    expect(stream['network'], 'hysteria');
    expect(stream['security'], 'tls');
    expect(stream['hysteriaSettings'], {'version': 2, 'auth': 'AUTH'});
    expect(stream['tlsSettings']['serverName'], 'cdn.example');
    expect(stream['tlsSettings']['alpn'], ['h3']);
  });

  test('hysteria2 без sni: serverName падает на host', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2, host: 'h.example', port: 443,
      params: {'password': 'AUTH'},
    );
    final out = buildXrayOutbound(node)!;
    expect(out['streamSettings']['tlsSettings']['serverName'], 'h.example');
  });

  test('hysteria2 с insecure=1', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2, host: 'h', port: 443,
      params: {'password': 'AUTH', 'insecure': '1'},
    );
    final out = buildXrayOutbound(node)!;
    expect(out['streamSettings']['tlsSettings']['allowInsecure'], true);
  });

  test('vless+xhttp+reality из share-ссылки', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h.example', port: 443,
      params: {
        'uuid': 'uid', 'type': 'xhttp', 'security': 'reality',
        'pbk': 'KEY', 'sid': 'ab', 'sni': 'www.apple.com',
        'fp': 'chrome', 'path': '/p', 'mode': 'auto',
      },
    );
    final out = buildXrayOutbound(node)!;
    expect(out['protocol'], 'vless');
    final vnext = (out['settings']['vnext'] as List).single as Map;
    expect(vnext['address'], 'h.example');
    expect(vnext['port'], 443);
    expect((vnext['users'] as List).single, {'id': 'uid', 'encryption': 'none'});
    final stream = out['streamSettings'] as Map<String, dynamic>;
    expect(stream['network'], 'xhttp');
    expect(stream['security'], 'reality');
    expect(stream['xhttpSettings'], {'path': '/p', 'mode': 'auto'});
    expect(stream['realitySettings'], {
      'serverName': 'www.apple.com', 'publicKey': 'KEY',
      'shortId': 'ab', 'fingerprint': 'chrome',
    });
  });

  test('vless+xhttp+tls с flow', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h.example', port: 443,
      params: {
        'uuid': 'uid', 'type': 'xhttp', 'security': 'tls',
        'sni': 'h.example', 'flow': 'xtls-rprx-vision', 'path': '/p',
      },
    );
    final out = buildXrayOutbound(node)!;
    final vnext = (out['settings']['vnext'] as List).single as Map;
    expect((vnext['users'] as List).single['flow'], 'xtls-rprx-vision');
    expect(out['streamSettings']['security'], 'tls');
    expect(out['streamSettings']['tlsSettings']['serverName'], 'h.example');
  });

  test('naive → null: у Xray такого протокола нет', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    expect(buildXrayOutbound(node), isNull);
  });

  test('нода в sing-box-схеме из подписки → null', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443, params: {},
      rawOutbound: {'type': 'vless', 'tag': 'proxy', 'server': 'h'},
    );
    expect(buildXrayOutbound(node), isNull);
  });
}
