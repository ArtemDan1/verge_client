import 'package:flutter/foundation.dart';
import 'profile.dart';
import 'app_settings.dart';
import 'network_settings.dart';
import 'routing_profile.dart';

@immutable
class PersistedState {
  final List<Profile> profiles;
  final String? activeProfileId;
  final AppSettings settings;
  final List<RoutingProfile> routingProfiles;
  final String? activeRoutingProfileId;

  /// Когда gee-наборы (.srs) в последний раз успешно обновлялись из сети.
  final DateTime? geoUpdatedAt;

  /// Стабильный per-install идентификатор устройства для панелей с HWID-привязкой.
  final String? hwid;

  final NetworkSettings networkSettings;

  const PersistedState({
    this.profiles = const [],
    this.activeProfileId,
    this.settings = const AppSettings(),
    this.routingProfiles = const [],
    this.activeRoutingProfileId,
    this.geoUpdatedAt,
    this.hwid,
    this.networkSettings = const NetworkSettings(),
  });

  PersistedState copyWith({
    List<Profile>? profiles,
    String? activeProfileId,
    bool clearActive = false,
    AppSettings? settings,
    List<RoutingProfile>? routingProfiles,
    String? activeRoutingProfileId,
    bool clearActiveRouting = false,
    DateTime? geoUpdatedAt,
    String? hwid,
    NetworkSettings? networkSettings,
  }) =>
      PersistedState(
        profiles: profiles ?? this.profiles,
        activeProfileId:
            clearActive ? null : (activeProfileId ?? this.activeProfileId),
        settings: settings ?? this.settings,
        routingProfiles: routingProfiles ?? this.routingProfiles,
        activeRoutingProfileId: clearActiveRouting
            ? null
            : (activeRoutingProfileId ?? this.activeRoutingProfileId),
        geoUpdatedAt: geoUpdatedAt ?? this.geoUpdatedAt,
        hwid: hwid ?? this.hwid,
        networkSettings: networkSettings ?? this.networkSettings,
      );

  Map<String, dynamic> toJson() => {
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'activeProfileId': activeProfileId,
        'settings': settings.toJson(),
        'routingProfiles': routingProfiles.map((r) => r.toJson()).toList(),
        'activeRoutingProfileId': activeRoutingProfileId,
        'geoUpdatedAt': geoUpdatedAt?.toIso8601String(),
        'hwid': hwid,
        'networkSettings': networkSettings.toJson(),
      };

  factory PersistedState.fromJson(Map<String, dynamic> json) => PersistedState(
        profiles: (json['profiles'] as List? ?? [])
            .map((e) => Profile.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        activeProfileId: json['activeProfileId'] as String?,
        settings: json['settings'] == null
            ? const AppSettings()
            : AppSettings.fromJson(
                (json['settings'] as Map).cast<String, dynamic>()),
        routingProfiles: (json['routingProfiles'] as List? ?? [])
            .map((e) =>
                RoutingProfile.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        activeRoutingProfileId: json['activeRoutingProfileId'] as String?,
        geoUpdatedAt: json['geoUpdatedAt'] == null
            ? null
            : DateTime.tryParse(json['geoUpdatedAt'] as String),
        hwid: json['hwid'] as String?,
        networkSettings: json['networkSettings'] == null
            ? const NetworkSettings()
            : NetworkSettings.fromJson(
                (json['networkSettings'] as Map).cast<String, dynamic>()),
      );
}
