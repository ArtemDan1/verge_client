import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
// SelectionArea живёт в material — берём точечно, остальной UI на shadcn.
import 'package:flutter/material.dart' show SelectionArea, Colors;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/log_entry.dart';
import '../theme/app_theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  /// Выбранные уровни. Пустое множество трактуется как «все» — иначе
  /// пользователь может случайно погасить последний чип и решить, что логи
  /// пропали.
  final Set<LogLevel> _levels = {};

  /// Источники: приложение / sing-box / Xray. Пусто — все.
  final Set<LogOrigin> _origins = {};

  String _query = '';

  bool _passes(LogEntry e) {
    if (_levels.isNotEmpty && !_levels.contains(e.level)) return false;
    if (_origins.isNotEmpty && !_origins.contains(e.origin)) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return e.message.toLowerCase().contains(q) ||
        (e.source?.toLowerCase().contains(q) ?? false);
  }

  void _toggle<T>(Set<T> set, T value) => setState(() {
        if (!set.remove(value)) set.add(value);
      });

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
          ShadInput(
            placeholder: const Text('Поиск по логам'),
            leading: const Icon(LucideIcons.search, size: 16),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          // Фильтры — переключаемые чипы, а не «от уровня»: так видно, что
          // именно показано, и уровни не приходится держать в голове
          // упорядоченными.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final o in LogOrigin.values)
                _FilterChip(
                  label: o.label,
                  active: _origins.contains(o),
                  color: _originColor(o, theme),
                  onTap: () => _toggle(_origins, o),
                ),
              const SizedBox(width: 8, height: 20),
              _Divider(color: theme.colorScheme.border),
              const SizedBox(width: 8, height: 20),
              for (final l in LogLevel.values)
                _FilterChip(
                  label: l.label,
                  active: _levels.contains(l),
                  color: _levelColor(l, theme),
                  onTap: () => _toggle(_levels, l),
                ),
              if (_levels.isNotEmpty || _origins.isNotEmpty)
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => setState(() {
                    _levels.clear();
                    _origins.clear();
                  }),
                  child: const Text('Сбросить'),
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

/// Вертикальный разделитель между группами фильтров.
class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, color: color);
}

/// Чип-переключатель фильтра: активный залит своим цветом, выключенный —
/// обводка с подсветкой по наведению.
class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final active = widget.active;
    final bg = active
        ? (_hovered
            ? Color.alphaBlend(Colors.white24, widget.color)
            : widget.color)
        : (_hovered ? theme.colorScheme.muted : null);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: active ? widget.color : theme.colorScheme.border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: active
                  ? const Color(0xFFFFFFFF)
                  : theme.colorScheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Одна строка: время · цветной бейдж уровня · источник · подсистема ·
/// сообщение.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.striped});

  final LogEntry entry;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final color = _levelColor(entry.level, theme);
    const mono = TextStyle(
      fontFamily: kMonoFontFamily,
      fontFamilyFallback: kMonoFontFallback,
      fontSize: 12,
      height: 1.45,
    );

    return Container(
      decoration: BoxDecoration(
        color: striped ? theme.colorScheme.muted.withValues(alpha: 0.35) : null,
        // Тонкая цветная полоса слева — уровень читается боковым зрением,
        // не вчитываясь в текст бейджа.
        border: Border(
          left: BorderSide(
            color: entry.level == LogLevel.error || entry.level == LogLevel.warn
                ? color
                : const Color(0x00000000),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.timeLabel, style: mono.copyWith(color: muted)),
          const SizedBox(width: 10),
          // Фиксированная ширина бейджей — сообщения выстраиваются в колонку.
          SizedBox(
            width: 56,
            child: _tag(entry.level.label, color, filled: true),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 68,
            child: _tag(entry.origin.label, _originColor(entry.origin, theme)),
          ),
          const SizedBox(width: 8),
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

  /// Компактный бейдж: залитый — для уровня, полупрозрачный — для источника,
  /// чтобы уровень оставался главным акцентом строки.
  Widget _tag(String label, Color color, {bool filled = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kMonoFontFamily,
            fontFamilyFallback: kMonoFontFallback,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ),
    );
  }
}

Color _levelColor(LogLevel level, ShadThemeData theme) => switch (level) {
      LogLevel.error => const Color(0xFFDC2626),
      LogLevel.warn => const Color(0xFFD97706),
      LogLevel.info => const Color(0xFF16A34A),
      _ => theme.colorScheme.mutedForeground,
    };

Color _originColor(LogOrigin origin, ShadThemeData theme) => switch (origin) {
      LogOrigin.app => const Color(0xFF6366F1),
      LogOrigin.singbox => const Color(0xFF0EA5E9),
      LogOrigin.xray => const Color(0xFFA855F7),
    };
