import 'package:flutter/foundation.dart';
import 'node_config.dart';
import 'subscription_info.dart';

@immutable
class Profile {
  final String id;
  final String name;
  final String url;
  final List<NodeConfig> nodes;
  final int? selectedNodeIndex;
  final DateTime? lastRefreshedAt;
  final SubscriptionInfo? subscriptionInfo;

  const Profile({
    required this.id,
    required this.name,
    required this.url,
    required this.nodes,
    required this.selectedNodeIndex,
    this.lastRefreshedAt,
    this.subscriptionInfo,
  });

  NodeConfig? get selectedNode {
    final i = selectedNodeIndex;
    if (i == null || i < 0 || i >= nodes.length) return null;
    return nodes[i];
  }

  Profile copyWith({
    String? name,
    String? url,
    List<NodeConfig>? nodes,
    int? selectedNodeIndex,
    bool clearSelection = false,
    DateTime? lastRefreshedAt,
    SubscriptionInfo? subscriptionInfo,
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'selectedNodeIndex': selectedNodeIndex,
        'lastRefreshedAt': lastRefreshedAt?.toUtc().toIso8601String(),
        'subscriptionInfo': subscriptionInfo?.toJson(),
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
      );
}
