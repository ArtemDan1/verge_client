import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/routing_rule.dart';
import 'package:singbox_client/models/routing_profile.dart';

void main() {
  const sample = RoutingProfile(
    id: 'p1',
    name: 'Тест',
    isBuiltIn: false,
    directRules: [RoutingRule(kind: RoutingRuleKind.geo, value: 'geoip-ru')],
    proxyRules: [],
    blockRules: [RoutingRule(kind: RoutingRuleKind.domain, value: 'ads.com')],
    finalAction: RoutingFinal.proxy,
  );

  test('JSON round-trip', () {
    expect(RoutingProfile.fromJson(sample.toJson()), sample);
  });

  test('finalAction по умолчанию proxy при отсутствии в JSON', () {
    final json = sample.toJson()..remove('finalAction');
    expect(RoutingProfile.fromJson(json).finalAction, RoutingFinal.proxy);
  });

  test('copyWith заменяет имя и сохраняет остальное', () {
    final c = sample.copyWith(name: 'Новое');
    expect(c.name, 'Новое');
    expect(c.directRules, sample.directRules);
    expect(c.id, 'p1');
  });
}
