import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/routing_profile.dart';
import 'package:singbox_client/models/routing_rule.dart';
import 'package:singbox_client/services/routing_presets.dart';

void main() {
  test('три пресета, все isBuiltIn, id стабильны и уникальны', () {
    final all = routingPresets();
    expect(all, hasLength(3));
    expect(all.every((p) => p.isBuiltIn), isTrue);
    final ids = all.map((p) => p.id).toList();
    expect(ids, ['preset-all-proxy', 'preset-bypass-ru', 'preset-block-ads']);
    expect(ids.toSet().length, 3);
  });

  test('«Всё через прокси» пустой, final=proxy', () {
    final p = routingPresets().firstWhere((p) => p.id == 'preset-all-proxy');
    expect(p.directRules, isEmpty);
    expect(p.proxyRules, isEmpty);
    expect(p.blockRules, isEmpty);
    expect(p.finalAction, RoutingFinal.proxy);
  });

  test('«Обход РФ» direct=geosite-category-ru+geoip-ru, block=ads, final=proxy', () {
    final p = routingPresets().firstWhere((p) => p.id == 'preset-bypass-ru');
    expect(p.directRules,
        contains(const RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-category-ru')));
    expect(p.directRules,
        contains(const RoutingRule(kind: RoutingRuleKind.geo, value: 'geoip-ru')));
    expect(p.blockRules, contains(const RoutingRule(
        kind: RoutingRuleKind.geo, value: 'geosite-category-ads-all')));
    expect(p.finalAction, RoutingFinal.proxy);
  });
}
