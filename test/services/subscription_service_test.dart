import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/subscription_service.dart';

void main() {
  test('декодит base64-подписку и парсит ноды', () async {
    const links =
        'vless://11111111-1111-1111-1111-111111111111@h:443?security=reality#A\n'
        'naive+https://u:p@h2:443#B';
    final body = base64.encode(utf8.encode(links));
    final svc = SubscriptionService(fetcher: (url) async => FetchResult(body, const {}));
    final nodes = await svc.load('https://example.com/sub');
    expect(nodes, hasLength(2));
    expect(nodes[0].protocol, NodeProtocol.vless);
    expect(nodes[1].protocol, NodeProtocol.naive);
  });

  test('пропускает нераспознанные строки', () async {
    const links = 'ss://bad\nvless://u@h:443#A';
    final body = base64.encode(utf8.encode(links));
    final svc = SubscriptionService(fetcher: (url) async => FetchResult(body, const {}));
    final nodes = await svc.load('https://x');
    expect(nodes, hasLength(1));
  });

  test('пустой результат → SubscriptionException', () async {
    final body = base64.encode(utf8.encode('ss://only-bad'));
    final svc = SubscriptionService(fetcher: (url) async => FetchResult(body, const {}));
    expect(() => svc.load('https://x'), throwsA(isA<SubscriptionException>()));
  });

  test('извлекает ноду из готового sing-box JSON-конфига', () async {
    const config = '''
{
  "inbounds": [{"type":"mixed","listen_port":2082}],
  "outbounds": [
    {"type":"naive","tag":"proxy","server":"cdn1.example","server_port":443,
     "username":"u","password":"p","tls":{"enabled":true,"server_name":"cdn1.example"}},
    {"type":"direct","tag":"direct"}
  ],
  "route": {"final": "proxy"}
}''';
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(config, const {}));
    final nodes = await svc.load('https://x');
    expect(nodes, hasLength(1)); // direct отфильтрован
    expect(nodes.first.protocol, NodeProtocol.naive);
    expect(nodes.first.host, 'cdn1.example');
    expect(nodes.first.port, 443);
    expect(nodes.first.name, 'proxy');
    expect(nodes.first.rawOutbound!['password'], 'p');
  });

  test('извлекает hysteria2-ноду из sing-box JSON-конфига', () async {
    const config = '''
{
  "outbounds": [
    {"type":"hysteria2","tag":"hy2-proxy","server":"hy.example.com","server_port":443,
     "password":"secret","tls":{"enabled":true,"server_name":"hy.example.com"}},
    {"type":"direct","tag":"direct"}
  ]
}''';
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(config, const {}));
    final nodes = await svc.load('https://x');
    expect(nodes, hasLength(1));
    expect(nodes.first.protocol, NodeProtocol.hysteria2);
    expect(nodes.first.host, 'hy.example.com');
    expect(nodes.first.rawOutbound!['password'], 'secret');
  });

  test('парсит hysteria2:// share-ссылку в подписке', () async {
    const links = 'hysteria2://pass@hy.example.com:443?sni=hy.example.com#HY2\n'
        'vless://u@h:443#V';
    final body = base64.encode(utf8.encode(links));
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(body, const {}));
    final nodes = await svc.load('https://x');
    expect(nodes, hasLength(2));
    expect(nodes[0].protocol, NodeProtocol.hysteria2);
    expect(nodes[1].protocol, NodeProtocol.vless);
  });

  test('rawOutbound нода прокидывается в конфиг как есть', () async {
    const config =
        '{"outbounds":[{"type":"naive","tag":"x","server":"h","server_port":443,"password":"secret"}]}';
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(config, const {}));
    final node = (await svc.load('https://x')).first;
    expect(node.rawOutbound!['password'], 'secret');
  });

  test('loadWithInfo извлекает subscription-userinfo из заголовков', () async {
    const links = 'vless://u@h:443#A';
    final svc = SubscriptionService(
      fetcher: (url) async => FetchResult(
        links,
        const {'subscription-userinfo': 'upload=1; download=2; total=10; expire=0'},
      ),
    );
    final res = await svc.loadWithInfo('https://x');
    expect(res.nodes, hasLength(1));
    expect(res.info, isNotNull);
    expect(res.info!.total, 10);
    expect(res.info!.used, 3);
  });

  test('шлёт заголовок x-hwid и User-Agent при HTTP-запросе', () async {
    late http.Request captured;
    final body = base64.encode(utf8.encode('vless://u@h:443#A'));
    final svc = SubscriptionService(
      hwid: 'dev-777',
      client: MockClient((req) async {
        captured = req;
        return http.Response(body, 200);
      }),
    );
    await svc.load('https://example.com/sub');
    expect(captured.headers['x-hwid'], 'dev-777');
    expect(captured.headers['User-Agent'], 'v2rayNG/1.8.0');
  });

  test('без hwid заголовок x-hwid не отправляется', () async {
    late http.Request captured;
    final body = base64.encode(utf8.encode('vless://u@h:443#A'));
    final svc = SubscriptionService(
      client: MockClient((req) async {
        captured = req;
        return http.Response(body, 200);
      }),
    );
    await svc.load('https://example.com/sub');
    expect(captured.headers.containsKey('x-hwid'), isFalse);
  });

  test('ответ-заглушка (все ноды 0.0.0.0) → SubscriptionException с remark', () async {
    const links =
        'vless://00000000-0000-0000-0000-000000000000@0.0.0.0:1?type=tcp#Превышен%20лимит%20устройств\n'
        'vless://00000000-0000-0000-0000-000000000000@0.0.0.0:1?type=tcp#Свяжитесь%20с%20нами';
    final body = base64.encode(utf8.encode(links));
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(body, const {}));
    await expectLater(
      svc.load('https://x'),
      throwsA(isA<SubscriptionException>().having(
          (e) => e.message, 'message', contains('Превышен лимит устройств'))),
    );
  });

  test('реальные ноды не считаются заглушкой', () async {
    const links = 'vless://u@real.example:443#A\nvless://u@1.2.3.4:443#B';
    final body = base64.encode(utf8.encode(links));
    final svc = SubscriptionService(fetcher: (_) async => FetchResult(body, const {}));
    final nodes = await svc.load('https://x');
    expect(nodes, hasLength(2));
  });
}
