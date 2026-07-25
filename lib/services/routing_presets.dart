import '../models/routing_profile.dart';
import '../models/routing_rule.dart';

/// Встроенные read-only профили роутинга. Сидятся при первом запуске.
List<RoutingProfile> routingPresets() => const [
      RoutingProfile(
        id: 'preset-all-proxy',
        name: 'Всё через прокси',
        isBuiltIn: true,
        directRules: [],
        proxyRules: [],
        blockRules: [],
        finalAction: RoutingFinal.proxy,
      ),
      RoutingProfile(
        id: 'preset-bypass-ru',
        name: 'Обход РФ',
        isBuiltIn: true,
        directRules: [
          RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru'),
          RoutingRule(kind: RoutingRuleKind.geo, value: 'geoip-ru'),
        ],
        proxyRules: [],
        blockRules: [
          RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ads-all'),
        ],
        finalAction: RoutingFinal.proxy,
      ),
      RoutingProfile(
        id: 'preset-block-ads',
        name: 'Только блок рекламы',
        isBuiltIn: true,
        directRules: [],
        proxyRules: [],
        blockRules: [
          RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ads-all'),
        ],
        finalAction: RoutingFinal.proxy,
      ),
    ];
