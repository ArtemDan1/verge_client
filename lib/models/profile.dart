import 'package:flutter/foundation.dart';
import 'node_config.dart';
import 'node_engine.dart';
import 'subscription_info.dart';

/// Ключ ноды для привязки настроек, переживающих обновление подписки.
/// Имя ноды в ключ НЕ входит: провайдеры регулярно переименовывают ноды
/// (флаги, метки скорости), а адрес остаётся тем же.
String nodeEngineKey(NodeConfig node) =>
    '${node.protocol.name}|${node.host}:${node.port}';

@immutable
class Profile {
  final String id;
  final String name;
  final String url;
  final List<NodeConfig> nodes;
  final int? selectedNodeIndex;
  final DateTime? lastRefreshedAt;
  final SubscriptionInfo? subscriptionInfo;

  /// Ручной выбор движка по ключу ноды. Переживает обновление подписки,
  /// потому что ключ построен по адресу, а не по имени.
  final Map<String, EngineChoice> engineOverrides;

  const Profile({
    required this.id,
    required this.name,
    required this.url,
    required this.nodes,
    required this.selectedNodeIndex,
    this.lastRefreshedAt,
    this.subscriptionInfo,
    this.engineOverrides = const {},
  });

  NodeConfig? get selectedNode {
    final i = selectedNodeIndex;
    if (i == null || i < 0 || i >= nodes.length) return null;
    return nodes[i];
  }

  EngineChoice engineChoiceFor(NodeConfig node) =>
      engineOverrides[nodeEngineKey(node)] ?? EngineChoice.auto;

  /// auto означает «нет записи»: так карта не копит мусор от нод,
  /// которых давно нет в подписке.
  Profile withEngineChoice(NodeConfig node, EngineChoice choice) {
    final map = Map<String, EngineChoice>.from(engineOverrides);
    if (choice == EngineChoice.auto) {
      map.remove(nodeEngineKey(node));
    } else {
      map[nodeEngineKey(node)] = choice;
    }
    return copyWith(engineOverrides: map);
  }

  Profile copyWith({
    String? name,
    String? url,
    List<NodeConfig>? nodes,
    int? selectedNodeIndex,
    bool clearSelection = false,
    DateTime? lastRefreshedAt,
    SubscriptionInfo? subscriptionInfo,
    Map<String, EngineChoice>? engineOverrides,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        nodes: nodes ?? this.nodes,
        selectedNodeIndex:
            clearSelection ? null : (selectedNodeIndex ?? this.selectedNodeIndex),
        lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
        subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
        engineOverrides: engineOverrides ?? this.engineOverrides,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'selectedNodeIndex': selectedNodeIndex,
        'lastRefreshedAt': lastRefreshedAt?.toUtc().toIso8601String(),
        'subscriptionInfo': subscriptionInfo?.toJson(),
        'engineOverrides':
            engineOverrides.map((k, v) => MapEntry(k, v.name)),
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        nodes: (json['nodes'] as List)
            .map((e) => NodeConfig.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        selectedNodeIndex: (json['selectedNodeIndex'] as num?)?.toInt(),
        lastRefreshedAt: json['lastRefreshedAt'] == null
            ? null
            : DateTime.parse(json['lastRefreshedAt'] as String),
        subscriptionInfo: json['subscriptionInfo'] == null
            ? null
            : SubscriptionInfo.fromJson(
                (json['subscriptionInfo'] as Map).cast<String, dynamic>()),
        engineOverrides: (json['engineOverrides'] as Map?)?.map(
              (k, v) => MapEntry('$k', EngineChoice.values.byName('$v')),
            ) ??
            const {},
      );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.name == name &&
      other.url == url &&
      listEquals(other.nodes, nodes) &&
      other.selectedNodeIndex == selectedNodeIndex &&
      other.lastRefreshedAt == lastRefreshedAt &&
      other.subscriptionInfo == subscriptionInfo &&
      mapEquals(other.engineOverrides, engineOverrides);

  @override
  int get hashCode => Object.hash(id, name, url, selectedNodeIndex, lastRefreshedAt,
      subscriptionInfo, Object.hashAll(nodes), Object.hashAllUnordered(engineOverrides.entries));
}
