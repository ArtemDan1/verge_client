import 'package:flutter/foundation.dart';
import 'node_config.dart';
import 'node_engine.dart';
import 'subscription_info.dart';
import 'subscription_meta.dart';

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
  final SubscriptionMeta? subscriptionMeta;

  /// Пользователь переименовал профиль вручную — profile-title из подписки
  /// больше не перетирает имя при обновлении.
  final bool nameIsCustom;

  /// Ручной выбор движка по ключу ноды. Переживает обновление подписки,
  /// потому что ключ построен по адресу, а не по имени.
  final Map<String, EngineChoice> engineOverrides;

  /// Свой интервал автообновления в минутах. null — значения нет, и тогда
  /// берётся интервал, присланный провайдером; если нет и его, профиль
  /// автоматически не обновляется. Отдельного флага «включено» нет намеренно:
  /// отсутствие значения и есть «выключено».
  final int? refreshIntervalMinutesOverride;

  const Profile({
    required this.id,
    required this.name,
    required this.url,
    required this.nodes,
    required this.selectedNodeIndex,
    this.lastRefreshedAt,
    this.subscriptionInfo,
    this.subscriptionMeta,
    this.nameIsCustom = false,
    this.engineOverrides = const {},
    this.refreshIntervalMinutesOverride,
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

  /// Через сколько минут профиль должен обновиться. null — не обновляется.
  int? get effectiveRefreshIntervalMinutes {
    final own = refreshIntervalMinutesOverride;
    if (own != null && own > 0) return own;
    final hours = subscriptionMeta?.updateIntervalHours;
    // Панели иногда шлют 0 — это «не обновлять», а не «обновлять постоянно».
    if (hours != null && hours > 0) return hours * 60;
    return null;
  }

  Profile copyWith({
    String? name,
    String? url,
    List<NodeConfig>? nodes,
    int? selectedNodeIndex,
    bool clearSelection = false,
    DateTime? lastRefreshedAt,
    SubscriptionInfo? subscriptionInfo,
    SubscriptionMeta? subscriptionMeta,
    bool? nameIsCustom,
    Map<String, EngineChoice>? engineOverrides,
    int? refreshIntervalMinutesOverride,
    bool clearRefreshInterval = false,
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
        subscriptionMeta: subscriptionMeta ?? this.subscriptionMeta,
        nameIsCustom: nameIsCustom ?? this.nameIsCustom,
        engineOverrides: engineOverrides ?? this.engineOverrides,
        refreshIntervalMinutesOverride: clearRefreshInterval
            ? null
            : (refreshIntervalMinutesOverride ?? this.refreshIntervalMinutesOverride),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'selectedNodeIndex': selectedNodeIndex,
        'lastRefreshedAt': lastRefreshedAt?.toUtc().toIso8601String(),
        'subscriptionInfo': subscriptionInfo?.toJson(),
        'subscriptionMeta': subscriptionMeta?.toJson(),
        'nameIsCustom': nameIsCustom,
        'engineOverrides':
            engineOverrides.map((k, v) => MapEntry(k, v.name)),
        'refreshIntervalMinutesOverride': refreshIntervalMinutesOverride,
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
        subscriptionMeta: json['subscriptionMeta'] == null
            ? null
            : SubscriptionMeta.fromJson(
                (json['subscriptionMeta'] as Map).cast<String, dynamic>()),
        // Отсутствие ключа = state, записанный до появления поля. Считаем имя
        // ручным, чтобы не перетереть то, что пользователь уже настроил.
        nameIsCustom: json['nameIsCustom'] as bool? ?? true,
        engineOverrides: (json['engineOverrides'] as Map?)?.map(
              (k, v) => MapEntry('$k', EngineChoice.values.byName('$v')),
            ) ??
            const {},
        refreshIntervalMinutesOverride:
            (json['refreshIntervalMinutesOverride'] as num?)?.toInt(),
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
      other.subscriptionMeta == subscriptionMeta &&
      other.nameIsCustom == nameIsCustom &&
      mapEquals(other.engineOverrides, engineOverrides) &&
      other.refreshIntervalMinutesOverride == refreshIntervalMinutesOverride;

  @override
  int get hashCode => Object.hash(id, name, url, selectedNodeIndex, lastRefreshedAt,
      subscriptionInfo, subscriptionMeta, nameIsCustom, Object.hashAll(nodes), Object.hashAllUnordered(engineOverrides.entries), refreshIntervalMinutesOverride);
}
