import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/routing_rule.dart';

void main() {
  test('JSON round-trip для каждого kind', () {
    for (final r in [
      const RoutingRule(kind: RoutingRuleKind.geo, value: 'geosite-ru'),
      const RoutingRule(kind: RoutingRuleKind.domain, value: 'example.com'),
      const RoutingRule(kind: RoutingRuleKind.ip, value: '1.2.3.0/24'),
    ]) {
      expect(RoutingRule.fromJson(r.toJson()), r);
    }
  });

  test('равенство по значению', () {
    expect(const RoutingRule(kind: RoutingRuleKind.geo, value: 'g'),
        const RoutingRule(kind: RoutingRuleKind.geo, value: 'g'));
    expect(const RoutingRule(kind: RoutingRuleKind.geo, value: 'g'),
        isNot(const RoutingRule(kind: RoutingRuleKind.ip, value: 'g')));
  });
}
