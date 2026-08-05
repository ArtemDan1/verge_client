import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/test_config_builder.dart';

NodeConfig _vless(String name) => NodeConfig(
      name: name,
      protocol: NodeProtocol.vless,
      host: '$name.example.com',
      port: 443,
      params: const {'id': '00000000-0000-0000-0000-000000000000'},
    );

NodeConfig _hy2(String name) => NodeConfig(
      name: name,
      protocol: NodeProtocol.hysteria2,
      host: '$name.example.com',
      port: 443,
      params: const {'password': 'pw'},
    );

void main() {
  test('ноды делятся по движку: hysteria2 уходит в xray', () {
    final split = splitByEngine([_vless('a'), _hy2('b')]);
    expect(split.singbox.map((n) => n.name), ['a']);
    expect(split.xray.map((n) => n.name), ['b']);
  });

  test('sing-box: по инбаунду на ноду, route связывает пары', () {
    final cfg = buildSingboxTestConfig([_vless('a'), _vless('b')],
        ports: [1111, 2222]);
    final inbounds = cfg['inbounds'] as List;
    expect(inbounds.length, 2);
    expect(inbounds[0]['type'], 'http');
    expect(inbounds[0]['tag'], 'test-in-0');
    expect(inbounds[0]['listen'], '127.0.0.1');
    expect(inbounds[0]['listen_port'], 1111);
    expect(inbounds[1]['listen_port'], 2222);

    final outbounds = cfg['outbounds'] as List;
    // Два прокси-outbound'а плюс direct для служебного трафика.
    expect(outbounds.map((o) => o['tag']),
        containsAll(['test-out-0', 'test-out-1', 'direct']));

    final rules = (cfg['route'] as Map)['rules'] as List;
    expect(rules[0]['inbound'], ['test-in-0']);
    expect(rules[0]['outbound'], 'test-out-0');
    expect(rules[1]['inbound'], ['test-in-1']);
    expect(rules[1]['outbound'], 'test-out-1');
  });

  test('xray: по инбаунду на ноду, routing связывает пары', () {
    final cfg = buildXrayTestConfig([_hy2('a')], ports: [3333]);
    final inbounds = cfg['inbounds'] as List;
    expect(inbounds.length, 1);
    expect(inbounds[0]['protocol'], 'http');
    expect(inbounds[0]['tag'], 'test-in-0');
    expect(inbounds[0]['port'], 3333);
    expect((cfg['outbounds'] as List).first['tag'], 'test-out-0');
    final rules = ((cfg['routing'] as Map)['rules'] as List);
    expect(rules[0]['inboundTag'], ['test-in-0']);
    expect(rules[0]['outboundTag'], 'test-out-0');
  });

  test('нода без xray-outbound пропускается, порядок портов сохраняется', () {
    // naive Xray не собирает — конфиг остаётся валидным и без неё.
    final naive = NodeConfig(
      name: 'n',
      protocol: NodeProtocol.naive,
      host: 'n.example.com',
      port: 443,
      params: const {},
    );
    final cfg = buildXrayTestConfig([naive, _hy2('a')], ports: [1, 2]);
    final inbounds = cfg['inbounds'] as List;
    expect(inbounds.length, 1);
    expect(inbounds[0]['port'], 2);
  });

  test('число портов должно совпадать с числом нод', () {
    expect(() => buildSingboxTestConfig([_vless('a')], ports: []),
        throwsArgumentError);
  });

  test('есть dns-сервер direct-dns, на который ссылаются outbound-ы', () {
    // Outbound из ConfigBuilder приходит с domain_resolver: direct-dns.
    // Без сервера с таким тегом sing-box падает с FATAL «domain resolver
    // not found» и весь замер молча превращается в «HTTP не прошёл».
    final cfg = buildSingboxTestConfig([_vless('a')], ports: [9000]);
    final out = (cfg['outbounds'] as List).first as Map;
    final servers = ((cfg['dns'] as Map)['servers'] as List).cast<Map>();
    expect(out['domain_resolver'], 'direct-dns');
    expect(servers.map((s) => s['tag']), contains('direct-dns'));
  });
}
