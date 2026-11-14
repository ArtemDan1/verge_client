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

  /// Периодический пинг активного соединения до gstatic (бейдж у таймера).
  /// Независим от Автовыбора — тот использует свой критерий для подбора ноды.
  final bool gstaticPingEnabled;
  final int gstaticPingIntervalSeconds;

  /// Адрес, до которого меряется пинг активного соединения. Меняется в
  /// настройках: у gstatic бывают свои проблемы с доступностью.
  final String gstaticPingUrl;

  /// Язык интерфейса: код из `appLanguages` или [systemLanguage].
  final String language;

  /// Глобальная горячая клавиша «подключить/отключить» в виде
  /// `ctrl+alt+V` (см. HotkeySpec), пустая строка — выключена.
  final String toggleHotkey;

  static const systemLanguage = 'system';

  static const defaultGstaticPingIntervalSeconds = 60;
  static const minGstaticPingIntervalSeconds = 1;
  static const maxGstaticPingIntervalSeconds = 3600;
  static const defaultGstaticPingUrl = 'https://www.gstatic.com/generate_204';

  static int clampGstaticPingInterval(int seconds) => seconds.clamp(
    minGstaticPingIntervalSeconds,
    maxGstaticPingIntervalSeconds,
  );

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localPort = 2080,
    this.networkService = 'auto',
    this.autostart = false,
    this.tunnelMode = TunnelMode.systemProxy,
    this.lastUpdateCheckAt,
    this.skippedVersion,
    this.gstaticPingEnabled = true,
    this.gstaticPingIntervalSeconds = defaultGstaticPingIntervalSeconds,
    this.gstaticPingUrl = defaultGstaticPingUrl,
    this.language = systemLanguage,
    this.toggleHotkey = '',
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? localPort,
    String? networkService,
    bool? autostart,
    TunnelMode? tunnelMode,
    DateTime? lastUpdateCheckAt,
    String? skippedVersion,
    bool? gstaticPingEnabled,
    int? gstaticPingIntervalSeconds,
    String? gstaticPingUrl,
    String? language,
    String? toggleHotkey,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    localPort: localPort ?? this.localPort,
    networkService: networkService ?? this.networkService,
    autostart: autostart ?? this.autostart,
    tunnelMode: tunnelMode ?? this.tunnelMode,
    lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
    skippedVersion: skippedVersion ?? this.skippedVersion,
    gstaticPingEnabled: gstaticPingEnabled ?? this.gstaticPingEnabled,
    gstaticPingIntervalSeconds: gstaticPingIntervalSeconds == null
        ? this.gstaticPingIntervalSeconds
        : clampGstaticPingInterval(gstaticPingIntervalSeconds),
    gstaticPingUrl: (gstaticPingUrl == null || gstaticPingUrl.trim().isEmpty)
        ? this.gstaticPingUrl
        : gstaticPingUrl.trim(),
    language: language ?? this.language,
    toggleHotkey: toggleHotkey ?? this.toggleHotkey,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'localPort': localPort,
    'networkService': networkService,
    'autostart': autostart,
    'tunnelMode': tunnelMode.name,
    'lastUpdateCheckAt': lastUpdateCheckAt?.toUtc().toIso8601String(),
    'skippedVersion': skippedVersion,
    'gstaticPingEnabled': gstaticPingEnabled,
    'gstaticPingIntervalSeconds': gstaticPingIntervalSeconds,
    'gstaticPingUrl': gstaticPingUrl,
    'language': language,
    'toggleHotkey': toggleHotkey,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: AppThemeMode.values.byName(json['themeMode'] as String),
    localPort: (json['localPort'] as num).toInt(),
    networkService: json['networkService'] as String,
    autostart: json['autostart'] as bool,
    tunnelMode: TunnelMode.values.byName(
      json['tunnelMode'] as String? ?? 'systemProxy',
    ),
    lastUpdateCheckAt: json['lastUpdateCheckAt'] == null
        ? null
        : DateTime.parse(json['lastUpdateCheckAt'] as String),
    skippedVersion: json['skippedVersion'] as String?,
    gstaticPingEnabled: json['gstaticPingEnabled'] as bool? ?? true,
    gstaticPingIntervalSeconds:
        (json['gstaticPingIntervalSeconds'] as num?)?.toInt() ??
        defaultGstaticPingIntervalSeconds,
    gstaticPingUrl:
        (json['gstaticPingUrl'] as String?)?.trim().isNotEmpty == true
        ? (json['gstaticPingUrl'] as String).trim()
        : defaultGstaticPingUrl,
    language: json['language'] as String? ?? systemLanguage,
    toggleHotkey: json['toggleHotkey'] as String? ?? '',
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
      other.skippedVersion == skippedVersion &&
      other.gstaticPingEnabled == gstaticPingEnabled &&
      other.gstaticPingIntervalSeconds == gstaticPingIntervalSeconds &&
      other.gstaticPingUrl == gstaticPingUrl &&
      other.language == language &&
      other.toggleHotkey == toggleHotkey;

  @override
  int get hashCode => Object.hash(
    themeMode,
    localPort,
    networkService,
    autostart,
    tunnelMode,
    lastUpdateCheckAt,
    skippedVersion,
    gstaticPingEnabled,
    gstaticPingIntervalSeconds,
    gstaticPingUrl,
    language,
    toggleHotkey,
  );
}
