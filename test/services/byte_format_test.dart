import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/byte_format.dart';

void main() {
  group('formatBytes', () {
    test('байты без дробной части', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
    });
    test('килобайты и мегабайты с одним знаком', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(67174), '65.6 KB');
      expect(formatBytes(1024 * 1024), '1.0 MB');
      expect(formatBytes(2254857830), '2.1 GB');
    });
  });

  group('formatSpeed', () {
    test('добавляет /s', () {
      expect(formatSpeed(0), '0 B/s');
      expect(formatSpeed(1258291), '1.2 MB/s');
    });
  });

  group('formatDuration', () {
    test('H:MM:SS', () {
      expect(formatDuration(Duration.zero), '0:00:00');
      expect(formatDuration(const Duration(minutes: 2, seconds: 9)), '0:02:09');
      expect(
        formatDuration(const Duration(hours: 13, minutes: 4, seconds: 5)),
        '13:04:05',
      );
    });
    test('отрицательная длительность схлопывается в ноль', () {
      expect(formatDuration(const Duration(seconds: -5)), '0:00:00');
    });
  });
}
