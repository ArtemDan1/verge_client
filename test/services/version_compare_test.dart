import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/version_compare.dart';

void main() {
  test('новее/старее/равно', () {
    expect(compareVersions('1.0.1', '1.0.0'), 1);
    expect(compareVersions('1.2.0', '1.1.9'), 1);
    expect(compareVersions('1.0.0', '1.0.1'), -1);
    expect(compareVersions('1.0.0', '1.0.0'), 0);
  });

  test('игнорирует ведущий v и суффикс +build, 1.0 == 1.0.0', () {
    expect(compareVersions('v1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0+5', '1.0.0+9'), 0);
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('v1.2.3', '1.2.0'), 1);
  });
}
