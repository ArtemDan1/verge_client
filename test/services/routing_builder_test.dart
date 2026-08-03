import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/routing_profile.dart';
import 'package:singbox_client/models/routing_rule.dart';
import 'package:singbox_client/services/routing_builder.dart';

void main() {
  const builder = RoutingBuilder();

  RoutingProfile profile({
    List<RoutingRule> allow = const [],
    List<RoutingRule> direct = const [],
    List<RoutingRule> proxy = const [],
    List<RoutingRule> block = const [],
    RoutingFinal fin = RoutingFinal.proxy,
    RoutingFinal allowAction = RoutingFinal.direct,
  }) =>
      RoutingProfile(
        id: 'p', name: 'p', isBuiltIn: false,
        allowRules: allow, allowAction: allowAction,
        directRules: direct, proxyRules: proxy, blockRules: block,
        finalAction: fin,
      );

  test('пустой профиль → нет правил, final=proxy, нет rule_set', () {
    final f = builder.build(profile(), tun: false);
    expect(f.rules, isEmpty);
    expect(f.ruleSets, isEmpty);
    expect(f.finalTag, 'proxy');
  });

  test('final=direct прокидывается в finalTag', () {
    final f = builder.build(profile(fin: RoutingFinal.direct));
    expect(f.finalTag, 'direct');
  });

  test('приоритет block→direct→proxy и корректные action/outbound', () {
    final f = builder.build(profile(
      block: const [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ads-all')],
      direct: const [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
      proxy: const [RoutingRule(kind: RoutingRuleKind.domain, value: 'x.com')],
    ));
    expect(f.rules[0]['rule_set'], ['geosite-category-ads-all']);
    expect(f.rules[0]['action'], 'reject');
    expect(f.rules[1]['rule_set'], ['geosite-category-ru']);
    expect(f.rules[1]['outbound'], 'direct');
    expect(f.rules[2]['domain_suffix'], ['x.com']);
    expect(f.rules[2]['outbound'], 'proxy');
  });

  test('allow перекрывает block: исключение из ads-листа уходит direct', () {
    final f = builder.build(profile(
      allow: const [
        RoutingRule(
            kind: RoutingRuleKind.domain, value: 'advert-api.wildberries.ru')
      ],
      block: const [
        RoutingRule(
            kind: RoutingRuleKind.geo, value: 'geosite-category-ads-all')
      ],
    ));
    expect(f.rules.first['domain_suffix'], ['advert-api.wildberries.ru']);
    expect(f.rules.first['outbound'], 'direct');
    expect(f.rules[1]['action'], 'reject');
  });

  test('allowAction=proxy направляет исключение в прокси', () {
    final f = builder.build(profile(
      allow: const [RoutingRule(kind: RoutingRuleKind.domain, value: 'x.com')],
      allowAction: RoutingFinal.proxy,
    ));
    expect(f.rules.first['outbound'], 'proxy');
  });

  test('в tun xray bypass, затем серверный IP и приватные сети раньше allow', () {
    final f = builder.build(
      profile(
          allow: const [
            RoutingRule(kind: RoutingRuleKind.domain, value: 'x.com')
          ]),
      tun: true,
      serverIp: '1.2.3.4',
    );
    expect((f.rules[0]['process_name'] as List).contains('xray'), isTrue);
    expect(f.rules[1]['ip_cidr'], contains('1.2.3.4/32'));
    expect(f.rules[2]['ip_is_private'], isTrue);
    expect(f.rules[3]['domain_suffix'], ['x.com']);
  });

  test('allow с direct резолвится через direct-dns (домены и geo)', () {
    final f = builder.build(profile(
      allow: const [
        RoutingRule(
            kind: RoutingRuleKind.domain, value: 'advert-api.wildberries.ru'),
        RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru'),
      ],
    ));
    final domainDns = f.dnsRules.firstWhere((r) => r['domain_suffix'] != null);
    expect(domainDns['domain_suffix'], ['advert-api.wildberries.ru']);
    expect(domainDns['server'], 'direct-dns');
    final geoDns = f.dnsRules.firstWhere((r) => r['rule_set'] != null);
    expect(geoDns['rule_set'], contains('geosite-category-ru'));
  });

  test('allowAction=proxy не добавляет direct-dns правил', () {
    final f = builder.build(profile(
      allow: const [
        RoutingRule(
            kind: RoutingRuleKind.domain, value: 'advert-api.wildberries.ru')
      ],
      allowAction: RoutingFinal.proxy,
    ));
    expect(f.dnsRules, isEmpty);
  });

  test('domain и ip правила в одной корзине дают раздельные записи', () {
    final f = builder.build(profile(direct: const [
      RoutingRule(kind: RoutingRuleKind.domain, value: 'a.com'),
      RoutingRule(kind: RoutingRuleKind.ip, value: '10.0.0.0/8'),
    ]));
    final direct = f.rules.where((r) => r['outbound'] == 'direct').toList();
    expect(direct.any((r) => r['domain_suffix'] != null), isTrue);
    expect(direct.any((r) => (r['ip_cidr'] as List).contains('10.0.0.0/8')), isTrue);
  });

  test('ruleSets дедуплицируются и содержат url из каталога', () {
    final f = builder.build(profile(
      direct: const [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
      proxy: const [RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')],
    ));
    expect(f.ruleSets, hasLength(1));
    expect(f.ruleSets.first['tag'], 'geosite-category-ru');
    expect(f.ruleSets.first['type'], 'remote');
    expect(f.ruleSets.first['url'], endsWith('geosite-category-ru.srs'));
    expect(f.ruleSets.first['download_detour'], 'proxy');
  });

  test('с geoAssetDir набор подключается локально (type: local, path)', () {
    final f = builder.build(
      profile(
        direct: const [
          RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')
        ],
      ),
      geoAssetDir: '/tmp/rule-sets',
    );
    expect(f.ruleSets, hasLength(1));
    expect(f.ruleSets.first['type'], 'local');
    expect(f.ruleSets.first['path'], '/tmp/rule-sets/geosite-category-ru.srs');
    expect(f.ruleSets.first.containsKey('url'), isFalse);
  });

  test('неизвестный geo-тег пропускается (нет в каталоге)', () {
    final f = builder.build(profile(
      direct: const [RoutingRule(kind: RoutingRuleKind.geo, value: 'nope-xyz')],
    ));
    expect(f.ruleSets, isEmpty);
    expect(f.rules.where((r) => r['rule_set'] != null), isEmpty);
  });

  test('tun: xray bypass первым, затем приватные и серверный IP в direct', () {
    final f = builder.build(profile(), tun: true, serverIp: '1.2.3.4');
    expect((f.rules[0]['process_name'] as List).contains('xray'), isTrue);
    expect(f.rules[0]['outbound'], 'direct');
    expect(f.rules[1]['ip_cidr'], contains('1.2.3.4/32'));
    expect(f.rules[1]['outbound'], 'direct');
    expect(f.rules.any((r) => r['ip_is_private'] == true && r['outbound'] == 'direct'),
        isTrue);
  });

  test('tun: xray process name обходит direct до приватных сетей', () {
    final f = builder.build(profile(), tun: true, serverIp: '1.2.3.4');
    final proc = f.rules.firstWhere(
      (r) => (r['process_name'] as List?)?.contains('xray') == true,
    );
    expect(proc['outbound'], 'direct');
    // Должно стоять раньше любого allow/proxy, чтобы петля sing-box → Xray не ушла в туннель.
    final procIndex = f.rules.indexOf(proc);
    expect(procIndex, 0);
  });
}
