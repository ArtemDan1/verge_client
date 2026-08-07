import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/app_settings.dart';

void main() {
  test('старый JSON с глобальным автообновлением читается без ошибки', () {
    final json = const AppSettings().toJson()
      ..['autoRefreshEnabled'] = true
      ..['autoRefreshIntervalMinutes'] = 360;
    final s = AppSettings.fromJson(json);
    expect(s.localPort, 2080);
  });

  test('toJson больше не содержит полей глобального автообновления', () {
    final json = const AppSettings().toJson();
    expect(json.containsKey('autoRefreshEnabled'), isFalse);
    expect(json.containsKey('autoRefreshIntervalMinutes'), isFalse);
  });

  test('поля апдейтера переживают round-trip', () {
    final s = const AppSettings().copyWith(
      lastUpdateCheckAt: DateTime.utc(2026, 8, 1, 12),
      skippedVersion: 'v1.2.3',
    );
    final back = AppSettings.fromJson(s.toJson());
    expect(back.lastUpdateCheckAt, DateTime.utc(2026, 8, 1, 12));
    expect(back.skippedVersion, 'v1.2.3');
  });

  test('старый JSON без полей апдейтера даёт null', () {
    final json = const AppSettings().toJson()
      ..remove('lastUpdateCheckAt')
      ..remove('skippedVersion');
    final s = AppSettings.fromJson(json);
    expect(s.lastUpdateCheckAt, isNull);
    expect(s.skippedVersion, isNull);
  });

  test('поля пинга gstatic имеют дефолты и переживают round-trip', () {
    const s = AppSettings();
    expect(s.gstaticPingEnabled, isTrue);
    expect(s.gstaticPingIntervalSeconds, 60);
    expect(s.gstaticPingUrl, 'https://www.gstatic.com/generate_204');

    final changed = s.copyWith(
      gstaticPingEnabled: false,
      gstaticPingIntervalSeconds: 45,
      gstaticPingUrl: 'https://example.com/ping',
    );
    final back = AppSettings.fromJson(changed.toJson());
    expect(back.gstaticPingEnabled, isFalse);
    expect(back.gstaticPingIntervalSeconds, 45);
    expect(back.gstaticPingUrl, 'https://example.com/ping');
  });

  test('старый JSON без полей пинга gstatic даёт дефолты', () {
    final json = const AppSettings().toJson()
      ..remove('gstaticPingEnabled')
      ..remove('gstaticPingIntervalSeconds')
      ..remove('gstaticPingUrl');
    final s = AppSettings.fromJson(json);
    expect(s.gstaticPingEnabled, isTrue);
    expect(s.gstaticPingIntervalSeconds, 60);
    expect(s.gstaticPingUrl, AppSettings.defaultGstaticPingUrl);
  });

  test('clampGstaticPingInterval держит интервал в 1..3600', () {
    expect(AppSettings.clampGstaticPingInterval(0), 1);
    expect(AppSettings.clampGstaticPingInterval(99999), 3600);
    expect(AppSettings.clampGstaticPingInterval(30), 30);
  });

  test('пустой адрес пинга не затирает сохранённый', () {
    const s = AppSettings(gstaticPingUrl: 'https://example.com/ping');
    expect(s.copyWith(gstaticPingUrl: '   ').gstaticPingUrl,
        'https://example.com/ping');
  });
}
