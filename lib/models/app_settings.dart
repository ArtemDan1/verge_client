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
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalMinutes;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localPort = 2080,
    this.networkService = 'auto',
    this.autostart = false,
    this.tunnelMode = TunnelMode.systemProxy,
    this.autoRefreshEnabled = false,
    this.autoRefreshIntervalMinutes = 360,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? localPort,
    String? networkService,
    bool? autostart,
    TunnelMode? tunnelMode,
    bool? autoRefreshEnabled,
    int? autoRefreshIntervalMinutes,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localPort: localPort ?? this.localPort,
        networkService: networkService ?? this.networkService,
        autostart: autostart ?? this.autostart,
        tunnelMode: tunnelMode ?? this.tunnelMode,
        autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
        autoRefreshIntervalMinutes:
            autoRefreshIntervalMinutes ?? this.autoRefreshIntervalMinutes,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'localPort': localPort,
        'networkService': networkService,
        'autostart': autostart,
        'tunnelMode': tunnelMode.name,
        'autoRefreshEnabled': autoRefreshEnabled,
        'autoRefreshIntervalMinutes': autoRefreshIntervalMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.byName(json['themeMode'] as String),
        localPort: (json['localPort'] as num).toInt(),
        networkService: json['networkService'] as String,
        autostart: json['autostart'] as bool,
        tunnelMode: TunnelMode.values
            .byName(json['tunnelMode'] as String? ?? 'systemProxy'),
        autoRefreshEnabled: json['autoRefreshEnabled'] as bool? ?? false,
        autoRefreshIntervalMinutes:
            (json['autoRefreshIntervalMinutes'] as num?)?.toInt() ?? 360,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.localPort == localPort &&
      other.networkService == networkService &&
      other.autostart == autostart &&
      other.tunnelMode == tunnelMode &&
      other.autoRefreshEnabled == autoRefreshEnabled &&
      other.autoRefreshIntervalMinutes == autoRefreshIntervalMinutes;

  @override
  int get hashCode => Object.hash(themeMode, localPort, networkService,
      autostart, tunnelMode, autoRefreshEnabled, autoRefreshIntervalMinutes);
}
