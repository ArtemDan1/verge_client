import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
// SelectionArea живёт в material — берём точечно, остальной UI на shadcn.
import 'package:flutter/material.dart' show SelectionArea;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/log_entry.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  /// Показывать записи не ниже выбранного уровня.
  LogLevel _minLevel = LogLevel.info;
  String _query = '';

  bool _passes(LogEntry e) {
    if (e.level.index < _minLevel.index) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return e.message.toLowerCase().contains(q) ||
        (e.source?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = ShadTheme.of(context);
    final all = c.logs;
    final logs = all.where(_passes).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Логи', style: theme.textTheme.large),
              const SizedBox(width: 8),
              Text('${logs.length} из ${all.length}',
                  style: theme.textTheme.muted),
              const Spacer(),
              ShadButton.outline(
                onPressed: () => Clipboard.setData(ClipboardData(
                    text: logs.map((e) => e.toPlainString()).join('\n'))),
                leading: const Icon(LucideIcons.clipboard, size: 16),
                child: const Text('Копировать'),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                onPressed: c.clearLogs,
                leading: const Icon(LucideIcons.trash2, size: 16),
                child: const Text('Очистить'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  placeholder: const Text('Поиск по логам'),
                  leading: const Icon(LucideIcons.search, size: 16),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              ShadSelect<LogLevel>(
                minWidth: 140,
                initialValue: _minLevel,
                options: [
                  for (final l in LogLevel.values)
                    ShadOption(value: l, child: Text('от ${l.label}')),
                ],
                selectedOptionBuilder: (ctx, v) => Text('от ${v.label}'),
                onChanged: (v) {
                  if (v != null) setState(() => _minLevel = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ShadCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                          all.isEmpty
                              ? 'Логов пока нет'
                              : 'Ничего не найдено по фильтру',
                          style: theme.textTheme.muted))
                  : SelectionArea(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: logs.length,
                        itemBuilder: (ctx, i) => _LogRow(
                          entry: logs[logs.length - 1 - i],
                          striped: i.isOdd,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна строка: время · бейдж уровня · подсистема · сообщение.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.striped});

  final LogEntry entry;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final color = _levelColor(entry.level, theme);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.45);

    return Container(
      color: striped ? theme.colorScheme.muted.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.timeLabel, style: mono.copyWith(color: muted)),
          const SizedBox(width: 10),
          // Фиксированная ширина бейджа — сообщения выстраиваются в колонку.
          SizedBox(
            width: 52,
            child: Text(entry.level.label,
                style: mono.copyWith(
                    color: color, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (entry.source != null)
                  TextSpan(
                    text: '${entry.source}  ',
                    style: mono.copyWith(
                        color: muted, fontWeight: FontWeight.w600),
                  ),
                TextSpan(
                  text: entry.message,
                  style: mono.copyWith(color: theme.colorScheme.foreground),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(LogLevel level, ShadThemeData theme) => switch (level) {
        LogLevel.error => const Color(0xFFDC2626),
        LogLevel.warn => const Color(0xFFD97706),
        LogLevel.info => const Color(0xFF16A34A),
        _ => theme.colorScheme.mutedForeground,
      };
}
