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

  test('версии-даты ГГГГ.М.Д: новее старой нумерации и сравниваются по дате', () {
    // Переход с 1.2.2 на даты: старые клиенты обязаны увидеть обновление.
    expect(compareVersions('v2026.11.3', '1.2.2'), 1);
    expect(compareVersions('2026.11.3', '2026.10.31'), 1);
    expect(compareVersions('2026.12.1', '2026.11.30'), 1);
    expect(compareVersions('2027.1.1', '2026.12.31'), 1);
  });
}
