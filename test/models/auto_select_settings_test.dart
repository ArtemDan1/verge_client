import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/auto_select_settings.dart';

void main() {
  test('дефолты', () {
    const s = AutoSelectSettings();
    expect(s.enabled, isFalse);
    expect(s.testUrl, 'https://www.gstatic.com/generate_204');
    expect(s.profileIds, isEmpty);
    expect(s.healthCheckIntervalSeconds, 60);
  });

  test('round-trip json', () {
    const s = AutoSelectSettings(
      enabled: true,
      testUrl: 'https://example.com',
      profileIds: {'a', 'b'},
      healthCheckIntervalSeconds: 120,
    );
    final back = AutoSelectSettings.fromJson(s.toJson());
    expect(back, s);
  });

  test('интервал зажимается по границам при чтении json', () {
    final low = AutoSelectSettings.fromJson({'healthCheckIntervalSeconds': 1});
    expect(low.healthCheckIntervalSeconds, 15);
    final high = AutoSelectSettings.fromJson({'healthCheckIntervalSeconds': 99999});
    expect(high.healthCheckIntervalSeconds, 3600);
  });

  test('битый json даёт дефолты, а не исключение', () {
    final s = AutoSelectSettings.fromJson({});
    expect(s, const AutoSelectSettings());
  });

  test('clampInterval', () {
    expect(AutoSelectSettings.clampInterval(0), 15);
    expect(AutoSelectSettings.clampInterval(60), 60);
    expect(AutoSelectSettings.clampInterval(10000), 3600);
  });
}
