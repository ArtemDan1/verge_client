/// Уровень строки лога. Порядок важен: используется для фильтра «от уровня».
enum LogLevel { trace, debug, info, warn, error }

extension LogLevelLabel on LogLevel {
  String get label => switch (this) {
        LogLevel.trace => 'TRACE',
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
      };
}

/// Разобранная строка лога: время, уровень, источник и текст.
///
/// sing-box печатает строки вида
/// `+0300 2026-07-25 12:00:00 INFO router: loaded rule-set` (с timestamp) или
/// вовсе без времени. Собственные сообщения приложения времени не содержат
/// никогда — поэтому [time] всегда проставлено: либо разобрано из строки,
/// либо взято в момент получения.
class LogEntry {
  LogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.source,
  });

  final DateTime time;
  final LogLevel level;

  /// Подсистема sing-box (`router`, `dns`, `inbound/tun` …), если её видно.
  final String? source;
  final String message;

  static final _prefix = RegExp(
    r'^\s*(?:[+-]\d{4}\s+)?' // смещение зоны: +0300
    r'(?:(\d{4})-(\d{2})-(\d{2})\s+)?' // дата
    r'(?:(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?\s+)?' // время
    r'(?:(TRACE|DEBUG|INFO|WARN|WARNING|ERROR|FATAL|PANIC)\s+)?', // уровень
    caseSensitive: false,
  );

  static final _source = RegExp(r'^([a-z0-9_./\[\]-]{1,40}):\s+');

  /// Разбирает сырую строку. [received] — момент получения, запасное время.
  factory LogEntry.parse(String raw, {DateTime? received}) {
    final now = received ?? DateTime.now();
    final line = raw.replaceAll('\r', '').trimRight();
    final m = _prefix.firstMatch(line);

    var time = now;
    var level = LogLevel.info;
    var rest = line;

    if (m != null && m.end > 0) {
      rest = line.substring(m.end);
      final hh = m.group(4);
      if (hh != null) {
        time = DateTime(
          int.tryParse(m.group(1) ?? '') ?? now.year,
          int.tryParse(m.group(2) ?? '') ?? now.month,
          int.tryParse(m.group(3) ?? '') ?? now.day,
          int.parse(hh),
          int.parse(m.group(5)!),
          int.parse(m.group(6)!),
        );
      }
      final lv = m.group(7)?.toUpperCase();
      if (lv != null) level = _levelOf(lv);
    }

    // Уровень мог не быть отдельным токеном (наши сообщения, паники Go).
    if (m?.group(7) == null) level = _guessLevel(rest);

    String? source;
    final sm = _source.firstMatch(rest);
    if (sm != null) {
      source = sm.group(1);
      rest = rest.substring(sm.end);
    }

    return LogEntry(
      time: time,
      level: level,
      message: rest.isEmpty ? line : rest,
      source: source,
    );
  }

  static LogLevel _levelOf(String s) => switch (s) {
        'TRACE' => LogLevel.trace,
        'DEBUG' => LogLevel.debug,
        'WARN' || 'WARNING' => LogLevel.warn,
        'ERROR' || 'FATAL' || 'PANIC' => LogLevel.error,
        _ => LogLevel.info,
      };

  static LogLevel _guessLevel(String s) {
    final l = s.toLowerCase();
    if (l.contains('error') ||
        l.contains('fatal') ||
        l.contains('panic') ||
        l.contains('failed')) {
      return LogLevel.error;
    }
    if (l.contains('warn')) return LogLevel.warn;
    return LogLevel.info;
  }

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  /// Представление для копирования в буфер.
  String toPlainString() {
    final src = source == null ? '' : '$source: ';
    return '$timeLabel ${level.label.padRight(5)} $src$message';
  }
}
