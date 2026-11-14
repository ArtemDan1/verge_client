import '../models/routing_profile.dart';
import '../models/routing_rule.dart';
import '../l10n/l10n.dart';

/// Имя профиля для показа: у встроенных — на языке интерфейса (в состоянии
/// лежит имя, с которым профиль когда-то засеяли).
extension RoutingProfileDisplayName on RoutingProfile {
  String get displayName {
    if (!isBuiltIn) return name;
    return switch (id) {
      'preset-all-proxy' => l10n.presetAllProxy,
      'preset-bypass-ru' => l10n.presetBypassRu,
      'preset-block-ads' => l10n.presetBlockAds,
      _ => name,
    };
  }
}

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
