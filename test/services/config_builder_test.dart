import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/models/routing_profile.dart';
import 'package:singbox_client/models/routing_rule.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/routing_presets.dart';

void main() {
  const builder = ConfigBuilder(localPort: 2080);

  test('vless+reality → корректный outbound', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'example.com', port: 443,
      params: {'uuid': 'uid', 'security': 'reality', 'pbk': 'KEY', 'sni': 'www.apple.com', 'sid': 'ab', 'fp': 'chrome', 'flow': 'xtls-rprx-vision'},
    );
    final cfg = builder.build(node);
    final inbound = cfg['inbounds'][0];
    expect(inbound['type'], 'mixed');
    expect(inbound['listen'], '127.0.0.1');
    expect(inbound['listen_port'], 2080);
    final out = cfg['outbounds'][0];
    expect(out['type'], 'vless');
    expect(out['server'], 'example.com');
    expect(out['server_port'], 443);
    expect(out['uuid'], 'uid');
    expect(out['flow'], 'xtls-rprx-vision');
    expect(out['tls']['enabled'], true);
    expect(out['tls']['server_name'], 'www.apple.com');
    expect(out['tls']['utls']['fingerprint'], 'chrome');
    expect(out['tls']['reality']['enabled'], true);
    expect(out['tls']['reality']['public_key'], 'KEY');
    expect(out['tls']['reality']['short_id'], 'ab');
  });

  test('naive → naive outbound с TLS', () {
    const node = NodeConfig(name: 'B', protocol: NodeProtocol.naive, host: 'h', port: 443, params: {'username': 'u', 'password': 'p'});
    final out = builder.build(node)['outbounds'][0];
    expect(out['type'], 'naive');
    expect(out['server'], 'h');
    expect(out['username'], 'u');
    expect(out['password'], 'p');
    expect(out['tls']['enabled'], true);
  });

  test('нода из Xray-подписки конвертируется при сборке', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2,
      host: 'h.example', port: 443, params: {},
      rawSchema: RawSchema.xray,
      rawOutbound: {
        'protocol': 'hysteria', 'tag': 'proxy',
        'settings': {'address': 'h.example', 'port': 443, 'version': 2},
        'streamSettings': {
          'network': 'hysteria', 'security': 'tls',
          'hysteriaSettings': {'version': 2, 'auth': 'AUTH'},
          'tlsSettings': {'serverName': 'sni.example', 'alpn': ['h3']},
        },
      },
    );
    final out = const ConfigBuilder(localPort: 2080).build(node)['outbounds'][0];
    expect(out['type'], 'hysteria2');
    expect(out['tag'], 'proxy');
    expect(out['password'], 'AUTH');
    expect(out['tls']['server_name'], 'sni.example');
    expect(out['domain_resolver'], 'direct-dns');
  });

  test('xraySocksPort → proxy становится socks на loopback', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2, host: 'h', port: 443,
      params: {'password': 'p'},
    );
    final out = const ConfigBuilder(localPort: 2080)
        .build(node, xraySocksPort: 11080)['outbounds'][0];
    expect(out['type'], 'socks');
    expect(out['tag'], 'proxy');
    expect(out['server'], '127.0.0.1');
    expect(out['server_port'], 11080);
    expect(out['version'], '5');
    // udp_over_tcp выключен: иначе UDP hysteria2 обернётся в TCP и потеряет смысл.
    expect(out['udp_over_tcp'], false);
    // domain_resolver не нужен: 127.0.0.1 резолвить нечего.
    expect(out.containsKey('domain_resolver'), isFalse);
  });

  test('TUN без routing-профиля всё равно даёт bypass xray и серверного IP', () {
    // Защита от петли sing-box → Xray → sing-box не должна зависеть от того,
    // выбран ли пользователем routing-профиль.
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.hysteria2, host: 'h', port: 443,
      params: {'password': 'p'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4', xraySocksPort: 11080);
    final rules = (cfg['route']['rules'] as List).cast<Map<String, dynamic>>();
    expect(
        rules.any((r) =>
            (r['process_name'] as List?)?.contains('xray') == true &&
            r['outbound'] == 'direct'),
        isTrue,
        reason: 'нет bypass процесса xray');
    expect(
        rules.any((r) =>
            (r['ip_cidr'] as List?)?.contains('1.2.3.4/32') == true),
        isTrue,
        reason: 'нет bypass серверного IP');
  });

  test('TUN-режим: tun inbound + bypass сервера + dns', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'example.com', port: 443,
      params: {'uuid': 'uid'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ));

    final inbound = cfg['inbounds'][0];
    expect(inbound['type'], 'tun');
    expect(inbound['auto_route'], true);
    expect(inbound['strict_route'], false);
    expect(inbound['stack'], 'gvisor');
    // Имя интерфейса не задаём: macOS требует формат utunN, sing-box выберет сам.
    expect(inbound.containsKey('interface_name'), false);

    final outs = cfg['outbounds'] as List;
    expect(outs.any((o) => o['type'] == 'vless' && o['tag'] == 'proxy'), true);
    expect(outs.any((o) => o['type'] == 'direct' && o['tag'] == 'direct'), true);

    final rules = cfg['route']['rules'] as List;
    expect(rules.any((r) =>
        (r['ip_cidr'] as List?)?.contains('1.2.3.4/32') == true &&
        r['outbound'] == 'direct'), true);
    expect(rules.any((r) => r['ip_is_private'] == true), true);
    expect(cfg['route']['final'], 'proxy');

    expect((cfg['dns']['servers'] as List).isNotEmpty, true);
    expect(cfg['dns']['final'], 'proxy-dns');
    expect(cfg['route']['default_domain_resolver'], 'proxy-dns');
  });

  test('TUN: sniff после ipv6/quic-reject, но до доменных правил', () {
    // sniff удерживает соединение до TLS ClientHello. Если он стоит до ipv6-reject,
    // IPv6-соединения держатся открытыми до ClientHello → Happy-Eyeballs коммитится
    // на IPv6 → reject уже поздно → ERR_CONNECTION_CLOSED. Поэтому ipv6/quic-reject
    // (мгновенные терминальные) должны идти ДО sniff, а доменные правила (geosite) —
    // ПОСЛЕ sniff, иначе домен неизвестен и они не матчатся.
    const node = NodeConfig(
      name: 'N', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
          proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ));
    final rules = (cfg['route']['rules'] as List).cast<Map<String, dynamic>>();
    final ipv6Idx = rules.indexWhere((r) => r['ip_version'] == 6);
    final quicIdx = rules.indexWhere(
        (r) => r['action'] == 'reject' && r['network'] == 'udp');
    final sniffIdx = rules.indexWhere((r) => r['action'] == 'sniff');
    final geoIdx = rules.indexWhere((r) =>
        (r['rule_set'] as List?)?.contains('geosite-category-ru') == true);
    expect(sniffIdx, greaterThanOrEqualTo(0), reason: 'нет sniff');
    expect(ipv6Idx, lessThan(sniffIdx), reason: 'ipv6-reject должен быть до sniff');
    expect(quicIdx, lessThan(sniffIdx), reason: 'quic-reject должен быть до sniff');
    expect(sniffIdx, lessThan(geoIdx), reason: 'sniff должен быть до доменных правил');
  });

  test('TUN+naive: QUIC отклоняется (naive не умеет UDP → откат на TCP)', () {
    const node = NodeConfig(
      name: 'N', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ));
    final rules = cfg['route']['rules'] as List;
    // Reject должен матчиться по network+port (L4), а НЕ по protocol: sing-box
    // 1.11+ не сниффит автоматически, а sniff в конфиге не включён — правило
    // protocol:quic было бы мёртвым, QUIC уходил бы в naive и дропался
    // (YouTube/Instagram не открываются).
    final quic = rules.cast<Map<String, dynamic>>().where(
        (r) => r['action'] == 'reject' && r['network'] == 'udp').toList();
    expect(quic, isNotEmpty, reason: 'нет sniffing-независимого reject UDP');
    expect(quic.first['port'], 443);
    expect(rules.any((r) => r.containsKey('protocol')), false,
        reason: 'protocol-правило требует сниффинга, которого нет');
  });

  test('TUN: hijack-dns первым правилом (иначе цензурируемый DNS роутера минует прокси)', () {
    // В TUN ОС резолвит через системный DNS. Запрос к LAN-роутеру (приватный IP)
    // без hijack ушёл бы direct → отравленный DNS РФ-провайдера (instagram→127.0.0.1).
    // hijack-dns заворачивает весь :53 в DNS-движок sing-box (резолв через прокси).
    // Должен стоять ПЕРВЫМ — раньше ip_is_private/direct-правил.
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ));
    final rules = cfg['route']['rules'] as List;
    expect(rules.first['action'], 'hijack-dns');
    expect(rules.first['port'], 53);
  });

  test('TUN: IPv6 отклоняется (proxy IPv4-only → браузер откатывается на IPv4)', () {
    // Браузер по Happy-Eyeballs/HTTPS-подсказкам лезет в IPv6 даже при ipv4_only
    // DNS. naive/прочие upstream — IPv4-only, IPv6-соединения зависают (сайты не
    // грузятся). reject заставляет браузер откатиться на IPv4, который проксируется.
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final rules = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ))['route']['rules'] as List;
    expect(rules.any((r) => r['ip_version'] == 6 && r['action'] == 'reject'),
        true);
    // hijack-dns должен остаться первым (DNS резолвится до отсева IPv6).
    expect(rules.first['action'], 'hijack-dns');
  });

  test('systemProxy НЕ hijack-dns (браузер отдаёт прокси домен, OS-DNS не при делах)', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final rules = builder.build(node)['route']['rules'] as List;
    expect(rules.any((r) => r['action'] == 'hijack-dns'), false);
  });

  test('TUN+vless: QUIC НЕ отклоняется (vless умеет UDP)', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'uid'},
    );
    final cfg = builder.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [], proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        ));
    final rules = cfg['route']['rules'] as List;
    expect(rules.any((r) => r['protocol'] == 'quic'), false);
  });

  test('systemProxy+naive: QUIC не трогаем (UDP в HTTP-прокси и так не идёт)', () {
    const node = NodeConfig(
      name: 'N', protocol: NodeProtocol.naive, host: 'h', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    final cfg = builder.build(node);
    final rules = cfg['route']['rules'] as List;
    expect(rules.any((r) => r['protocol'] == 'quic'), false);
  });

  test('hysteria2 → hysteria2 outbound с TLS', () {
    const node = NodeConfig(
      name: 'H', protocol: NodeProtocol.hysteria2, host: 'hy.example.com', port: 443,
      params: {'password': 'secret', 'sni': 'hy.example.com'},
    );
    final out = builder.build(node)['outbounds'][0];
    expect(out['type'], 'hysteria2');
    expect(out['server'], 'hy.example.com');
    expect(out['server_port'], 443);
    expect(out['password'], 'secret');
    expect(out['tls']['enabled'], true);
    expect(out['tls']['server_name'], 'hy.example.com');
  });

  test('systemProxy режим не меняет существующий mixed-конфиг', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final cfg = builder.build(node);
    expect(cfg['inbounds'][0]['type'], 'mixed');
    // DNS теперь есть и в systemProxy: резолв по умолчанию через прокси,
    // чтобы отравленный провайдерский DNS не ломал geoip-матчинг.
    expect(cfg['dns']['final'], 'proxy-dns');
    expect(cfg['route']['default_domain_resolver'], 'proxy-dns');
    final proxyOut = (cfg['outbounds'] as List)
        .firstWhere((o) => o['tag'] == 'proxy');
    expect(proxyOut['domain_resolver'], 'direct-dns');
  });

  test('direct-dns bootstrap DoH uses Yandex TLS server name', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final cfg = builder.build(node);
    final directDns = (cfg['dns']['servers'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['tag'] == 'direct-dns');

    expect(directDns['type'], 'https');
    expect(directDns['server'], '77.88.8.8');
    expect(directDns['tls']['server_name'], 'common.dot.dns.yandex.net');
    // sing-box 1.13 падает с FATAL "detour to an empty direct outbound makes
    // no sense", если у DNS-сервера стоит detour на пустой direct. Поэтому
    // detour быть не должно.
    expect(directDns.containsKey('detour'), false);
  });

  test('direct-dns сервер маршрутизируется direct (без bootstrap-петли)', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    // Даже в "Всё через прокси" соединение к direct-dns (77.88.8.8) должно идти
    // напрямую, иначе резолв адреса прокси уходит через ещё не поднятый прокси.
    final cfg = builder.build(node);
    final rules = cfg['route']['rules'] as List;
    expect(rules.any((r) =>
        (r['ip_cidr'] as List?)?.contains('77.88.8.8/32') == true &&
        r['outbound'] == 'direct'), true);
  });

  test('systemProxy всегда содержит direct outbound', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final outs = builder.build(node)['outbounds'] as List;
    expect(outs.any((o) => o['type'] == 'direct' && o['tag'] == 'direct'), true);
  });

  test('routing-профиль добавляет route.rules, rule_set и cache_file', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    const routing = RoutingProfile(
      id: 'r', name: 'r', isBuiltIn: false,
      directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
      proxyRules: [], blockRules: [],
      finalAction: RoutingFinal.proxy,
    );
    final cfg = builder.build(node, routing: routing);
    final rules = cfg['route']['rules'] as List;
    expect(rules.any((r) =>
        (r['rule_set'] as List?)?.contains('geosite-category-ru') == true &&
        r['outbound'] == 'direct'), true);
    expect((cfg['route']['rule_set'] as List).any((s) => s['tag'] == 'geosite-category-ru'),
        true);
    expect(cfg['experimental']['cache_file']['enabled'], true);
    expect(cfg['route']['final'], 'proxy');
  });

  test('cache_file использует абсолютный путь в geoAssetDir', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    const routing = RoutingProfile(
      id: 'r', name: 'r', isBuiltIn: false,
      directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
      proxyRules: [], blockRules: [],
      finalAction: RoutingFinal.proxy,
    );
    // cwd запущенного из /Applications процесса = "/", относительный cache.db
    // падает с FATAL "read-only file system". Путь обязан быть абсолютным.
    const withGeo = ConfigBuilder(localPort: 2080, geoAssetDir: '/tmp/geo');
    final cfg = withGeo.build(node, routing: routing);
    expect(cfg['experimental']['cache_file']['path'], '/tmp/geo/cache.db');
  });

  test('TUN использует отдельный cache_file, чтобы не конфликтовать с systemProxy', () {
    // systemProxy-sing-box (от пользователя) и TUN-sing-box (от root через
    // helper) могут работать одновременно. bbolt берёт эксклюзивный flock на
    // cache.db: второй процесс не получает лок и падает с
    // "initialize cache-file: timeout". Поэтому пути кэша должны различаться.
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    const routing = RoutingProfile(
      id: 'r', name: 'r', isBuiltIn: false,
      directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
      proxyRules: [], blockRules: [],
      finalAction: RoutingFinal.proxy,
    );
    const withGeo = ConfigBuilder(localPort: 2080, geoAssetDir: '/tmp/geo');
    final proxyPath =
        withGeo.build(node, routing: routing)['experimental']['cache_file']['path'];
    final tunPath = withGeo.build(node,
        mode: TunnelMode.tun, serverIp: '1.2.3.4',
        routing: routing)['experimental']['cache_file']['path'];
    expect(proxyPath, '/tmp/geo/cache.db');
    expect(tunPath, '/tmp/geo/cache-tun.db');
    expect(proxyPath == tunPath, false);
  });

  test('routing final=direct ставит route.final=direct', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    const routing = RoutingProfile(
      id: 'r', name: 'r', isBuiltIn: false,
      directRules: [], proxyRules: [], blockRules: [],
      finalAction: RoutingFinal.direct,
    );
    expect(builder.build(node, routing: routing)['route']['final'], 'direct');
  });

  test('preset-all-proxy генерирует route.final=proxy', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final routing = routingPresets()
        .firstWhere((p) => p.id == 'preset-all-proxy');

    final cfg = builder.build(node, routing: routing);

    expect(cfg['route']['final'], 'proxy');
    // Пользовательских правил нет, но всегда есть bootstrap-правило для direct-dns.
    final rules = cfg['route']['rules'] as List;
    expect(rules.every((r) =>
        (r['ip_cidr'] as List?)?.contains('77.88.8.8/32') == true), true);
  });

  test('preset-bypass-ru генерирует RU direct rules и route.final=proxy', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
      params: {'uuid': 'u'},
    );
    final routing = routingPresets()
        .firstWhere((p) => p.id == 'preset-bypass-ru');

    final cfg = builder.build(node, routing: routing);
    final rules = cfg['route']['rules'] as List;

    expect(cfg['route']['final'], 'proxy');
    expect(rules.any((r) =>
        (r['rule_set'] as List?)?.contains('geosite-category-ru') == true &&
        r['outbound'] == 'direct'), true);
    expect(rules.any((r) =>
        (r['rule_set'] as List?)?.contains('geoip-ru') == true &&
        r['outbound'] == 'direct'), true);
  });

  group('clash api', () {
    NodeConfig node() => const NodeConfig(
          name: 'A', protocol: NodeProtocol.vless, host: 'h', port: 443,
          params: {'uuid': 'u'},
        );
    RoutingProfile routingWithGeo() => const RoutingProfile(
          id: 'r', name: 'r', isBuiltIn: false,
          directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
          proxyRules: [], blockRules: [],
          finalAction: RoutingFinal.proxy,
        );

    test('без креденшелов секции нет', () {
      final cfg = const ConfigBuilder().build(node());
      expect((cfg['experimental'] as Map?)?['clash_api'], isNull);
      expect((cfg['route'] as Map)['find_process'], isNull);
    });

    test('в system-proxy добавляет clash_api и find_process', () {
      final cfg = const ConfigBuilder(
        clashApiPort: 39999,
        clashApiSecret: 's3cret',
      ).build(node());
      final api = (cfg['experimental'] as Map)['clash_api'] as Map;
      expect(api['external_controller'], '127.0.0.1:39999');
      expect(api['secret'], 's3cret');
      expect((cfg['route'] as Map)['find_process'], isTrue);
    });

    test('в TUN тоже добавляет', () {
      final cfg = const ConfigBuilder(
        clashApiPort: 39999,
        clashApiSecret: 's3cret',
      ).build(node(), mode: TunnelMode.tun);
      final api = (cfg['experimental'] as Map)['clash_api'] as Map;
      expect(api['external_controller'], '127.0.0.1:39999');
      expect((cfg['route'] as Map)['find_process'], isTrue);
    });

    test('не затирает cache_file', () {
      final cfg = ConfigBuilder(
        geoAssetDir: '/tmp/geo',
        clashApiPort: 39999,
        clashApiSecret: 's3cret',
      ).build(node(), routing: routingWithGeo());
      final exp = cfg['experimental'] as Map;
      expect(exp['cache_file'], isNotNull);
      expect(exp['clash_api'], isNotNull);
    });
  });
}
