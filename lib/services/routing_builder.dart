import '../models/routing_profile.dart';
import '../models/routing_rule.dart';
import 'geo_catalog.dart';

class RoutingFragment {
  final List<Map<String, dynamic>> rules;
  final List<Map<String, dynamic>> ruleSets;
  final String finalTag;

  /// DNS-правила: домены, уходящие direct, должны и резолвиться напрямую
  /// (через direct-dns), а не через прокси. Остальное резолвит proxy-dns.
  final List<Map<String, dynamic>> dnsRules;

  const RoutingFragment(this.rules, this.ruleSets, this.finalTag,
      {this.dnsRules = const []});
}

class RoutingBuilder {
  const RoutingBuilder();

  /// Локальный набор (вшит в приложение и распакован на диск) предпочтительнее:
  /// прямой путь к raw.githubusercontent.com в РФ часто блокируется, а sing-box
  /// падает с FATAL, если remote rule-set не загрузился. Если папка с наборами
  /// не передана — откатываемся на remote-загрузку через proxy.
  Map<String, dynamic> _ruleSetEntry(GeoCategory cat, String? geoAssetDir) {
    if (geoAssetDir != null) {
      return {
        'type': 'local',
        'tag': cat.tag,
        'format': 'binary',
        'path': '$geoAssetDir/${cat.tag}.srs',
      };
    }
    return {
      'type': 'remote',
      'tag': cat.tag,
      'format': 'binary',
      'url': cat.srsUrl,
      'download_detour': 'proxy',
      'update_interval': '7d',
    };
  }

  RoutingFragment build(RoutingProfile profile,
      {String? serverIp, bool tun = false, String? geoAssetDir}) {
    final rules = <Map<String, dynamic>>[];
    final ruleSets = <String, Map<String, dynamic>>{};

    // TUN bypass идёт первым.
    if (tun) {
      // Трафик самого Xray-процесса не должен уходить в прокси: иначе
      // sing-box → Xray → sing-box → петля. find_process даёт process_name.
      // Тестовый sing-box здесь по той же причине: в TUN его замер поехал бы
      // через сам туннель и показывал бы «всё хорошо» на мёртвой ноде.
      // Боевой процесс называется `sing-box` и под правило не попадает.
      rules.add({
        'process_name': ['xray', 'sing-box-test'],
        'outbound': 'direct'
      });
      if (serverIp != null && serverIp.isNotEmpty) {
        rules.add({'ip_cidr': ['$serverIp/32'], 'outbound': 'direct'});
      }
      rules.add({'ip_is_private': true, 'outbound': 'direct'});
    }

    void emit(List<RoutingRule> bucket, Map<String, dynamic> Function() base) {
      final geo = <String>[];
      final domains = <String>[];
      final ips = <String>[];
      for (final r in bucket) {
        switch (r.kind) {
          case RoutingRuleKind.geo:
            final cat = geoCategoryByTag(r.value);
            if (cat == null) break;
            geo.add(cat.tag);
            ruleSets.putIfAbsent(cat.tag, () => _ruleSetEntry(cat, geoAssetDir));
            break;
          case RoutingRuleKind.domain:
            domains.add(r.value);
            break;
          case RoutingRuleKind.ip:
            // sing-box ip_cidr ждёт CIDR — «голый» IP нормализуем в /32.
            ips.add(r.value.contains('/') ? r.value : '${r.value}/32');
            break;
        }
      }
      if (geo.isNotEmpty) rules.add({...base(), 'rule_set': geo});
      if (ips.isNotEmpty) rules.add({...base(), 'ip_cidr': ips});
      if (domains.isNotEmpty) rules.add({...base(), 'domain_suffix': domains});
    }

    // Исключения — раньше блоклиста: пользовательское правило должно
    // перекрывать грубый гео-набор, а не наоборот.
    final allowTag =
        profile.allowAction == RoutingFinal.direct ? 'direct' : 'proxy';
    emit(profile.allowRules, () => {'outbound': allowTag});
    emit(profile.blockRules, () => {'action': 'reject'});
    emit(profile.directRules, () => {'outbound': 'direct'});
    emit(profile.proxyRules, () => {'outbound': 'proxy'});

    final finalTag =
        profile.finalAction == RoutingFinal.direct ? 'direct' : 'proxy';

    // Всё, что идёт direct, должно и резолвиться напрямую: иначе прокси вернёт
    // «свой» IP и исключение поедет не туда.
    final directBuckets = [
      profile.directRules,
      if (profile.allowAction == RoutingFinal.direct) profile.allowRules,
    ].expand((b) => b).toList();

    final directGeo = directBuckets
        .where((r) => r.kind == RoutingRuleKind.geo)
        .map((r) => geoCategoryByTag(r.value)?.tag)
        .whereType<String>()
        .toSet()
        .toList();
    // Домены — только из allow: direct-корзина исторически задаётся гео-наборами,
    // а точечное исключение без своего DNS-правила работать не будет.
    final allowDomains = profile.allowAction == RoutingFinal.direct
        ? profile.allowRules
            .where((r) => r.kind == RoutingRuleKind.domain)
            .map((r) => r.value)
            .toList()
        : const <String>[];

    final dnsRules = <Map<String, dynamic>>[
      if (allowDomains.isNotEmpty)
        {'domain_suffix': allowDomains, 'server': 'direct-dns'},
      if (directGeo.isNotEmpty) {'rule_set': directGeo, 'server': 'direct-dns'},
    ];

    return RoutingFragment(rules, ruleSets.values.toList(), finalTag,
        dnsRules: dnsRules);
  }
}
