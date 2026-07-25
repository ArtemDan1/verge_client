import 'package:flutter/foundation.dart';

enum RoutingRuleKind { geo, domain, ip }

@immutable
class RoutingRule {
  final RoutingRuleKind kind;
  final String value;

  const RoutingRule({required this.kind, required this.value});

  Map<String, dynamic> toJson() => {'kind': kind.name, 'value': value};

  factory RoutingRule.fromJson(Map<String, dynamic> json) => RoutingRule(
        kind: RoutingRuleKind.values.byName(json['kind'] as String),
        value: json['value'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is RoutingRule && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}
