import 'package:flutter/foundation.dart';

/// Автовыбор ноды: приложение само подбирает самую быструю живую ноду в
/// отмеченных профилях и следит, что она не умерла посреди сессии.
@immutable
class AutoSelectSettings {
  static const defaultTestUrl = 'https://www.gstatic.com/generate_204';
  static const defaultIntervalSeconds = 60;

  /// Нижняя граница интервала — не короче таймаута самой проверки (5 с) с
  /// запасом: иначе фоновые тики наложатся друг на друга.
  static const minIntervalSeconds = 15;
  static const maxIntervalSeconds = 3600;

  final bool enabled;
  final String testUrl;

  /// Профили, в которых подбирается лучшая нода. Остальные не трогаем.
  final Set<String> profileIds;

  final int healthCheckIntervalSeconds;

  const AutoSelectSettings({
    this.enabled = false,
    this.testUrl = defaultTestUrl,
    this.profileIds = const {},
    this.healthCheckIntervalSeconds = defaultIntervalSeconds,
  });

  static int clampInterval(int seconds) =>
      seconds.clamp(minIntervalSeconds, maxIntervalSeconds);

  /// Есть ли из чего выбирать. Отмеченные профили — это пул кандидатов:
  /// лучшая нода ищется по ним всем сразу, а не внутри активного профиля.
  bool get isActive => enabled && profileIds.isNotEmpty;

  bool covers(String? profileId) =>
      enabled && profileId != null && profileIds.contains(profileId);

  AutoSelectSettings copyWith({
    bool? enabled,
    String? testUrl,
    Set<String>? profileIds,
    int? healthCheckIntervalSeconds,
  }) =>
      AutoSelectSettings(
        enabled: enabled ?? this.enabled,
        testUrl: testUrl ?? this.testUrl,
        profileIds: profileIds ?? this.profileIds,
        healthCheckIntervalSeconds: healthCheckIntervalSeconds == null
            ? this.healthCheckIntervalSeconds
            : clampInterval(healthCheckIntervalSeconds),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'testUrl': testUrl,
        'profileIds': profileIds.toList(),
        'healthCheckIntervalSeconds': healthCheckIntervalSeconds,
      };

  /// Состояние, записанное версией без автовыбора, читается как дефолты —
  /// поэтому каждый ключ необязательный.
  factory AutoSelectSettings.fromJson(Map<String, dynamic> json) =>
      AutoSelectSettings(
        enabled: json['enabled'] as bool? ?? false,
        testUrl: (json['testUrl'] as String?)?.trim().isNotEmpty == true
            ? (json['testUrl'] as String).trim()
            : defaultTestUrl,
        profileIds: {
          for (final e in (json['profileIds'] as List? ?? [])) e as String
        },
        healthCheckIntervalSeconds: clampInterval(
            (json['healthCheckIntervalSeconds'] as num?)?.toInt() ??
                defaultIntervalSeconds),
      );

  @override
  bool operator ==(Object other) =>
      other is AutoSelectSettings &&
      other.enabled == enabled &&
      other.testUrl == testUrl &&
      setEquals(other.profileIds, profileIds) &&
      other.healthCheckIntervalSeconds == healthCheckIntervalSeconds;

  @override
  int get hashCode => Object.hash(enabled, testUrl,
      Object.hashAllUnordered(profileIds), healthCheckIntervalSeconds);
}
