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
    expect(raw['protocol'], 'hysteria');
    expect(raw['tag'], 'proxy');
    expect(raw['streamSettings']['hysteriaSettings']['auth'],
        '17733a01-8e8f-4432-aa82-7f856dc9dc2a');
  });

  test('хранит ОРИГИНАЛЬНЫЙ Xray-outbound, а не конвертированный', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"hysteria",
   "settings":{"address":"193.233.133.11","port":443,"version":2},
   "streamSettings":{"network":"hysteria",
     "hysteriaSettings":{"version":2,"auth":"AUTH"},
     "security":"tls",
     "tlsSettings":{"serverName":"cdn1.example","alpn":["h3"]}}}],
  "remarks":"FR"}]''';
    final n = parseXrayConfigs(json)!.single;
    expect(n.rawSchema, RawSchema.xray);
    expect(n.host, '193.233.133.11');
    expect(n.port, 443);
    expect(n.rawOutbound!['protocol'], 'hysteria');
    expect(n.rawOutbound!['streamSettings']['hysteriaSettings']['auth'], 'AUTH');
  });

  test('xhttp-транспорт больше не теряется', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"vless",
   "settings":{"vnext":[{"address":"h.example","port":443,
     "users":[{"id":"uid","encryption":"none"}]}]},
   "streamSettings":{"network":"xhttp","security":"reality",
     "xhttpSettings":{"path":"/p","mode":"auto"},
     "realitySettings":{"serverName":"www.apple.com","publicKey":"KEY","shortId":"ab"}}}],
  "remarks":"X"}]''';
    final n = parseXrayConfigs(json)!.single;
    expect(n.transport, 'xhttp');
    expect(n.rawOutbound!['streamSettings']['xhttpSettings']['path'], '/p');
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
    expect(raw['protocol'], 'vless');
    expect(raw['streamSettings']['network'], 'ws');
  });

  test('конвертирует trojan', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"trojan",
   "settings":{"servers":[{"address":"t.com","port":443,"password":"pw"}]},
   "streamSettings":{"security":"tls","tlsSettings":{"serverName":"t.com"}}}],
  "remarks":"T"}]''';
    final n = parseXrayConfigs(json)!.first;
    expect(n.rawOutbound!['protocol'], 'trojan');
    expect(n.rawOutbound!['settings']['servers'][0]['password'], 'pw');
  });

  test('конвертирует shadowsocks', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"shadowsocks",
   "settings":{"servers":[{"address":"s.com","port":8388,"method":"aes-256-gcm","password":"pw"}]}}],
  "remarks":"S"}]''';
    final n = parseXrayConfigs(json)!.first;
    expect(n.rawOutbound!['protocol'], 'shadowsocks');
    expect(n.rawOutbound!['settings']['servers'][0]['method'], 'aes-256-gcm');
    expect(n.rawOutbound!['settings']['servers'][0]['password'], 'pw');
  });

  test('пропускает конфиг без proxy-outbound', () {
    const json = '[{"outbounds":[{"tag":"direct","protocol":"freedom"}],"remarks":"X"}]';
    expect(parseXrayConfigs(json), isEmpty);
  });
}
