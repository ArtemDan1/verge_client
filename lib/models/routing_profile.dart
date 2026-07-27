import 'package:flutter/foundation.dart';
import 'routing_rule.dart';

enum RoutingFinal { proxy, direct }

@immutable
class RoutingProfile {
  final String id;
  final String name;
  final bool isBuiltIn;

  /// Исключения. Эмитятся ПЕРВЫМИ — раньше blockRules, — чтобы конкретный
  /// домен можно было вытащить из-под грубого гео-блоклиста
  /// (например advert-api.wildberries.ru зашит в geosite-category-ads-all).
  final List<RoutingRule> allowRules;

  /// Куда отправлять allowRules: direct (по умолчанию) или proxy.
  final RoutingFinal allowAction;

  final List<RoutingRule> directRules;
  final List<RoutingRule> proxyRules;
  final List<RoutingRule> blockRules;
  final RoutingFinal finalAction;

  const RoutingProfile({
    required this.id,
    required this.name,
    required this.isBuiltIn,
    this.allowRules = const [],
    this.allowAction = RoutingFinal.direct,
    required this.directRules,
    required this.proxyRules,
    required this.blockRules,
    required this.finalAction,
  });

  RoutingProfile copyWith({
    String? name,
    List<RoutingRule>? allowRules,
    RoutingFinal? allowAction,
    List<RoutingRule>? directRules,
    List<RoutingRule>? proxyRules,
    List<RoutingRule>? blockRules,
    RoutingFinal? finalAction,
  }) =>
      RoutingProfile(
        id: id,
        name: name ?? this.name,
        isBuiltIn: isBuiltIn,
        allowRules: allowRules ?? this.allowRules,
        allowAction: allowAction ?? this.allowAction,
        directRules: directRules ?? this.directRules,
        proxyRules: proxyRules ?? this.proxyRules,
        blockRules: blockRules ?? this.blockRules,
        finalAction: finalAction ?? this.finalAction,
      );

  static List<RoutingRule> _rules(dynamic raw) => ((raw as List?) ?? const [])
      .map((e) => RoutingRule.fromJson((e as Map).cast<String, dynamic>()))
      .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBuiltIn': isBuiltIn,
        'allowRules': allowRules.map((r) => r.toJson()).toList(),
        'allowAction': allowAction.name,
        'directRules': directRules.map((r) => r.toJson()).toList(),
        'proxyRules': proxyRules.map((r) => r.toJson()).toList(),
        'blockRules': blockRules.map((r) => r.toJson()).toList(),
        'finalAction': finalAction.name,
      };

  factory RoutingProfile.fromJson(Map<String, dynamic> json) => RoutingProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
        allowRules: _rules(json['allowRules']),
        allowAction: RoutingFinal.values
            .byName(json['allowAction'] as String? ?? 'direct'),
        directRules: _rules(json['directRules']),
        proxyRules: _rules(json['proxyRules']),
        blockRules: _rules(json['blockRules']),
        finalAction: RoutingFinal.values
            .byName(json['finalAction'] as String? ?? 'proxy'),
      );

  @override
  bool operator ==(Object other) =>
      other is RoutingProfile &&
      other.id == id &&
      other.name == name &&
      other.isBuiltIn == isBuiltIn &&
      listEquals(other.allowRules, allowRules) &&
      other.allowAction == allowAction &&
      listEquals(other.directRules, directRules) &&
      listEquals(other.proxyRules, proxyRules) &&
      listEquals(other.blockRules, blockRules) &&
      other.finalAction == finalAction;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        isBuiltIn,
        Object.hashAll(allowRules),
        allowAction,
        Object.hashAll(directRules),
        Object.hashAll(proxyRules),
        Object.hashAll(blockRules),
        finalAction,
      );
}
