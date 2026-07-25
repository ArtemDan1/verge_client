import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/xray_config_parser.dart';

void main() {
  test('не-массив → null', () {
    expect(parseXrayConfigs('{"outbounds":[]}'), isNull);
    expect(parseXrayConfigs('not json'), isNull);
  });

  test('парсит реальный Xray hysteria2-конфиг из Remnawave', () {
    // Реальный ответ подписки (UA v2rayNG) — одна hysteria2-нода.
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"hysteria",
   "settings":{"address":"193.233.133.11","port":443,"version":2},
   "streamSettings":{"network":"hysteria",
     "hysteriaSettings":{"version":2,"auth":"17733a01-8e8f-4432-aa82-7f856dc9dc2a"},
     "security":"tls",
     "tlsSettings":{"serverName":"cdn1.mentorhoroscope.online","fingerprint":"chrome","alpn":["h3"]}}},
  {"tag":"direct","protocol":"freedom"},
  {"tag":"block","protocol":"blackhole"}],
  "remarks":"FR Mentor"}]''';
    final nodes = parseXrayConfigs(json)!;
    expect(nodes, hasLength(1));
    final n = nodes.first;
    expect(n.protocol, NodeProtocol.hysteria2);
    expect(n.name, 'FR Mentor');
    expect(n.host, '193.233.133.11');
    expect(n.port, 443);
    final raw = n.rawOutbound!;
    expect(raw['type'], 'hysteria2');
    expect(raw['tag'], 'proxy');
    expect(raw['password'], '17733a01-8e8f-4432-aa82-7f856dc9dc2a');
    expect(raw['tls']['server_name'], 'cdn1.mentorhoroscope.online');
    expect(raw['tls']['alpn'], ['h3']);
  });

  test('конвертирует vless+ws', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"vless",
   "settings":{"vnext":[{"address":"ex.com","port":443,
     "users":[{"id":"uuid-1","flow":"xtls-rprx-vision","encryption":"none"}]}]},
   "streamSettings":{"network":"ws","security":"tls",
     "tlsSettings":{"serverName":"sni.com"},
     "wsSettings":{"path":"/ws","headers":{"Host":"sni.com"}}}}],
  "remarks":"V"}]''';
    final n = parseXrayConfigs(json)!.first;
    expect(n.protocol, NodeProtocol.vless);
    final raw = n.rawOutbound!;
    expect(raw['type'], 'vless');
    expect(raw['uuid'], 'uuid-1');
    expect(raw['flow'], 'xtls-rprx-vision');
    expect(raw['tls']['server_name'], 'sni.com');
    expect(raw['transport']['type'], 'ws');
    expect(raw['transport']['path'], '/ws');
    expect(raw['transport']['headers']['Host'], 'sni.com');
  });

  test('конвертирует trojan', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"trojan",
   "settings":{"servers":[{"address":"t.com","port":443,"password":"pw"}]},
   "streamSettings":{"security":"tls","tlsSettings":{"serverName":"t.com"}}}],
  "remarks":"T"}]''';
    final n = parseXrayConfigs(json)!.first;
    expect(n.rawOutbound!['type'], 'trojan');
    expect(n.rawOutbound!['password'], 'pw');
  });

  test('конвертирует shadowsocks', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"shadowsocks",
   "settings":{"servers":[{"address":"s.com","port":8388,"method":"aes-256-gcm","password":"pw"}]}}],
  "remarks":"S"}]''';
    final n = parseXrayConfigs(json)!.first;
    expect(n.rawOutbound!['type'], 'shadowsocks');
    expect(n.rawOutbound!['method'], 'aes-256-gcm');
    expect(n.rawOutbound!['password'], 'pw');
  });

  test('пропускает конфиг без proxy-outbound', () {
    const json = '[{"outbounds":[{"tag":"direct","protocol":"freedom"}],"remarks":"X"}]';
    expect(parseXrayConfigs(json), isEmpty);
  });
}
