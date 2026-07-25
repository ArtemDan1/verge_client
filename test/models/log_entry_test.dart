import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/log_entry.dart';

void main() {
  group('LogEntry.parse', () {
    test('разбирает строку sing-box с зоной, датой, временем и уровнем', () {
      final e = LogEntry.parse(
          '+0300 2026-07-25 12:34:56 INFO router: loaded rule-set geoip-ru');
      expect(e.level, LogLevel.info);
      expect(e.timeLabel, '12:34:56');
      expect(e.time.year, 2026);
      expect(e.source, 'router');
      expect(e.message, 'loaded rule-set geoip-ru');
    });

    test('разбирает строку без даты', () {
      final e = LogEntry.parse('12:00:01 ERROR dns: lookup failed');
      expect(e.level, LogLevel.error);
      expect(e.timeLabel, '12:00:01');
      expect(e.source, 'dns');
      expect(e.message, 'lookup failed');
    });

    test('WARNING приводится к warn', () {
      expect(LogEntry.parse('2026-07-25 01:02:03 WARNING x: y').level,
          LogLevel.warn);
    });

    test('строке без времени подставляется момент получения', () {
      final at = DateTime(2026, 7, 25, 9, 8, 7);
      final e = LogEntry.parse('tun start failed: helper unavailable',
          received: at);
      expect(e.time, at);
      expect(e.timeLabel, '09:08:07');
      // Уровень выводится из текста, отдельного токена нет.
      expect(e.level, LogLevel.error);
      expect(e.message, 'tun start failed: helper unavailable');
    });

    test('обычное сообщение без маркеров — info', () {
      final e = LogEntry.parse('sing-box started');
      expect(e.level, LogLevel.info);
      expect(e.source, isNull);
      expect(e.message, 'sing-box started');
    });

    test('toPlainString содержит время, уровень и источник', () {
      final e = LogEntry.parse('2026-07-25 12:00:00 INFO dns: ok');
      expect(e.toPlainString(), '12:00:00 INFO  dns: ok');
    });
  });
}
