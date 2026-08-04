import 'package:flutter/foundation.dart';

enum AppThemeMode { system, light, dark }

enum TunnelMode { systemProxy, tun }

@immutable
class AppSettings {
  final AppThemeMode themeMode;
  final int localPort;
  final String networkService;
  final bool autostart;
  final TunnelMode tunnelMode;

  /// Когда последний раз ходили в GitHub Releases. Пишется независимо от
  /// результата, чтобы неудачные проверки не долбили API при каждом запуске.
  final DateTime? lastUpdateCheckAt;

  /// Версия, про которую пользователь нажал «Пропустить». Баннер и бейдж по
  /// ней не показываются; следующая версия покажется снова.
  final String? skippedVersion;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localPort = 2080,
    this.networkService = 'auto',
    this.autostart = false,
    this.tunnelMode = TunnelMode.systemProxy,
    this.lastUpdateCheckAt,
    this.skippedVersion,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? localPort,
    String? networkService,
    bool? autostart,
    TunnelMode? tunnelMode,
    DateTime? lastUpdateCheckAt,
    String? skippedVersion,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localPort: localPort ?? this.localPort,
        networkService: networkService ?? this.networkService,
        autostart: autostart ?? this.autostart,
        tunnelMode: tunnelMode ?? this.tunnelMode,
        lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
        skippedVersion: skippedVersion ?? this.skippedVersion,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'localPort': localPort,
        'networkService': networkService,
        'autostart': autostart,
        'tunnelMode': tunnelMode.name,
        'lastUpdateCheckAt': lastUpdateCheckAt?.toUtc().toIso8601String(),
        'skippedVersion': skippedVersion,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.byName(json['themeMode'] as String),
        localPort: (json['localPort'] as num).toInt(),
        networkService: json['networkService'] as String,
        autostart: json['autostart'] as bool,
        tunnelMode: TunnelMode.values
            .byName(json['tunnelMode'] as String? ?? 'systemProxy'),
        lastUpdateCheckAt: json['lastUpdateCheckAt'] == null
            ? null
            : DateTime.parse(json['lastUpdateCheckAt'] as String),
        skippedVersion: json['skippedVersion'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.localPort == localPort &&
      other.networkService == networkService &&
      other.autostart == autostart &&
      other.tunnelMode == tunnelMode &&
      other.lastUpdateCheckAt == lastUpdateCheckAt &&
      other.skippedVersion == skippedVersion;

  @override
  int get hashCode => Object.hash(themeMode, localPort, networkService,
      autostart, tunnelMode, lastUpdateCheckAt, skippedVersion);
}
