import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/app_settings.dart';

void main() {
  test('дефолты', () {
    const s = AppSettings();
    expect(s.themeMode, AppThemeMode.system);
    expect(s.localPort, 2080);
    expect(s.networkService, 'auto');
    expect(s.autostart, false);
  });

  test('JSON round-trip', () {
    const s = AppSettings(themeMode: AppThemeMode.dark, localPort: 1080, networkService: 'Wi-Fi', autostart: true);
    expect(AppSettings.fromJson(s.toJson()), equals(s));
  });

  test('copyWith меняет одно поле', () {
    const s = AppSettings();
    expect(s.copyWith(localPort: 3000).localPort, 3000);
    expect(s.copyWith(localPort: 3000).themeMode, AppThemeMode.system);
  });

  test('tunnelMode по умолчанию systemProxy и переживает JSON', () {
    const s = AppSettings();
    expect(s.tunnelMode, TunnelMode.systemProxy);
    final round = AppSettings.fromJson(
        s.copyWith(tunnelMode: TunnelMode.tun).toJson());
    expect(round.tunnelMode, TunnelMode.tun);
  });

  test('autoRefresh дефолты — выключено, 360 минут', () {
    const s = AppSettings();
    expect(s.autoRefreshEnabled, false);
    expect(s.autoRefreshIntervalMinutes, 360);
  });

  test('autoRefresh JSON round-trip с новыми полями', () {
    const s = AppSettings(autoRefreshEnabled: true, autoRefreshIntervalMinutes: 60);
    expect(AppSettings.fromJson(s.toJson()), equals(s));
  });

  test('fromJson старого JSON без новых полей использует дефолты', () {
    final json = {'themeMode': 'system', 'localPort': 2080, 'networkService': 'auto', 'autostart': false, 'tunnelMode': 'systemProxy'};
    final s = AppSettings.fromJson(json);
    expect(s.autoRefreshEnabled, false);
    expect(s.autoRefreshIntervalMinutes, 360);
  });
}
