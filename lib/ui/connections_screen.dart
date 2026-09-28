import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart' show SelectionArea, showGeneralDialog;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../app/app_controller.dart';
import '../models/connection_info.dart';
import '../services/byte_format.dart';
import '../theme/app_theme.dart';
import '../theme/verge_palette.dart';
import '../tunnel/tunnel_controller.dart';
import 'widgets/paper.dart';

/// Поиск идёт по домену, IP и имени приложения; пустой набор [kinds] означает
/// «не фильтровать», а не «ничего не показывать».
List<ConnectionInfo> filterConnections(
  List<ConnectionInfo> all, {
  required String query,
  required Set<OutboundKind> kinds,
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final c in all)
      if ((kinds.isEmpty || kinds.contains(c.outboundKind)) &&
          (q.isEmpty ||
              c.host.toLowerCase().contains(q) ||
              c.destinationIP.toLowerCase().contains(q) ||
              (c.appName ?? '').toLowerCase().contains(q)))
        c,
  ];
}

const _kindLabels = {
  OutboundKind.proxy: 'Прокси',
  OutboundKind.direct: 'Напрямую',
  OutboundKind.block: 'Блок',
};

/// Группа соединений одного приложения.
class _AppGroup {
  _AppGroup(this.name);
  final String name;
  final items = <ConnectionInfo>[];
  int get upload => items.fold(0, (a, c) => a + c.upload);
  int get download => items.fold(0, (a, c) => a + c.download);
}

/// Соединения без известного процесса (TUN без атрибуции, системные службы)
/// собираются в одну группу.
const _kUnknownApp = 'Другие';

List<_AppGroup> _groupByApp(List<ConnectionInfo> list) {
  final byName = <String, _AppGroup>{};
  for (final c in list) {
    final name = (c.appName == null || c.appName!.isEmpty)
        ? _kUnknownApp
        : c.appName!;
    byName.putIfAbsent(name, () => _AppGroup(name)).items.add(c);
  }
  // Сверху — самые «тяжёлые» по трафику приложения.
  return byName.values.toList()
    ..sort((a, b) =>
        (b.download + b.upload).compareTo(a.download + a.upload));
}

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _search = TextEditingController();
  final _kinds = <OutboundKind>{};
  bool _grouped = true;
  // Длительность тикает раз в секунду независимо от снапшотов Clash API.
  late final Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    return Padding(
      padding: kScreenPadding,
      child: ValueListenableBuilder<List<ConnectionInfo>>(
        valueListenable: widget.controller.connections,
        builder: (context, all, _) {
          final byQuery =
              filterConnections(all, query: _search.text, kinds: const {});
          int countOf(OutboundKind k) =>
              byQuery.where((c) => c.outboundKind == k).length;
          final list = filterConnections(
            all,
            query: _search.text,
            kinds: _kinds,
          )..sort((a, b) => b.start.compareTo(a.start));

          final Widget body;
          if (all.isEmpty) {
            body = Center(
              child: Text(
                widget.controller.status == TunnelStatus.connected
                    ? 'Нет активных соединений'
                    : 'VPN отключён',
                style: theme.textTheme.muted,
              ),
            );
          } else if (list.isEmpty) {
            body = Center(
              child: Text('Ничего не найдено', style: theme.textTheme.muted),
            );
          } else if (_grouped) {
            final groups = _groupByApp(list);
            body = ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GroupCard(
                  group: groups[i],
                  now: _now,
                  onTap: _showDetails,
                ),
              ),
            );
          } else {
            body = Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: palette.panelBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _ConnectionRow(
                  key: ValueKey(list[i].id),
                  conn: list[i],
                  now: _now,
                  showApp: true,
                  first: i == 0,
                  onTap: () => _showDetails(list[i]),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Соединения',
                actions: [
                  SizedBox(
                    width: 260,
                    child: Segmented<bool>(
                      value: _grouped,
                      height: 36,
                      onChanged: (v) => setState(() => _grouped = v),
                      options: const [
                        SegmentedOption(value: true, label: 'По приложениям'),
                        SegmentedOption(value: false, label: 'Списком'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _search,
                      placeholder: const Text('Домен, IP или приложение'),
                      leading: const Icon(LucideIcons.search, size: 16),
                      decoration: ShadDecoration(color: palette.surface),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _KindPill(
                    label: 'Все · ${byQuery.length}',
                    selected: _kinds.isEmpty,
                    onTap: () => setState(_kinds.clear),
                  ),
                  for (final k in OutboundKind.values) ...[
                    const SizedBox(width: 6),
                    _KindPill(
                      label: '${_kindLabels[k]} · ${countOf(k)}',
                      selected: _kinds.length == 1 && _kinds.contains(k),
                      onTap: () => setState(() {
                        // Один вид за раз: «Все» сбрасывает, повторный клик
                        // по активному — тоже.
                        final was = _kinds.contains(k) && _kinds.length == 1;
                        _kinds.clear();
                        if (!was) _kinds.add(k);
                      }),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  /// Детали соединения — выдвижная панель справа, как в макете. Раньше это
  /// был ShadSheet, который растягивался на всё окно.
  void _showDetails(ConnectionInfo c) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть',
      barrierColor: const Color(0x33000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.centerRight,
        child: _ConnectionDrawer(
          initial: c,
          connections: widget.controller.connections,
        ),
      ),
      transitionBuilder: (ctx, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? theme.colorScheme.primaryForeground
                  : theme.colorScheme.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Цветной чип маршрута: прокси — кобальт, напрямую — зелёный, блок — красный.
class _RouteChip extends StatelessWidget {
  const _RouteChip(this.kind);
  final OutboundKind kind;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    final dark = ShadTheme.of(context).brightness == Brightness.dark;
    final (bg, fg, label) = switch (kind) {
      OutboundKind.proxy => (
          dark ? palette.accent.withValues(alpha: 0.18) : const Color(0xFFE8EDFF),
          palette.accentText,
          'прокси'
        ),
      OutboundKind.direct => (
          dark ? palette.success.withValues(alpha: 0.18) : const Color(0xFFE3F4EA),
          palette.successText,
          'напрямую'
        ),
      OutboundKind.block => (palette.dangerSoft, palette.dangerText, 'блок'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// Плитка-инициал приложения; цвет стабилен для имени.
class _AppTile extends StatelessWidget {
  const _AppTile(this.name);
  final String name;

  static const _colors = [
    Color(0xFF3D6BE0),
    Color(0xFF2A8FBF),
    Color(0xFF6B6860),
    Color(0xFF5865C9),
    Color(0xFF1F8A5B),
    Color(0xFFB0602A),
    Color(0xFF8A4FBF),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[name.hashCode.abs() % _colors.length];
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.now,
    required this.onTap,
  });

  final _AppGroup group;
  final DateTime now;
  final ValueChanged<ConnectionInfo> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final n = group.items.length;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: palette.surfaceHeader,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _AppTile(group.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_plural(n), style: theme.textTheme.muted.copyWith(fontSize: 13)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 170,
                  child: Text(
                    '↑ ${formatBytes(group.upload)}  ↓ ${formatBytes(group.download)}',
                    textAlign: TextAlign.right,
                    style: monoStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          for (final c in group.items)
            _ConnectionRow(
              key: ValueKey(c.id),
              conn: c,
              now: now,
              showApp: false,
              first: false,
              onTap: () => onTap(c),
            ),
        ],
      ),
    );
  }

  static String _plural(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    final word = mod10 == 1 && mod100 != 11
        ? 'соединение'
        : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
            ? 'соединения'
            : 'соединений';
    return '$n $word';
  }
}

class _ConnectionRow extends StatefulWidget {
  const _ConnectionRow({
    super.key,
    required this.conn,
    required this.now,
    required this.showApp,
    required this.first,
    required this.onTap,
  });

  final ConnectionInfo conn;
  final DateTime now;

  /// В плоском списке показываем приложение, в группе — нет (оно в шапке).
  final bool showApp;
  final bool first;
  final VoidCallback onTap;

  @override
  State<_ConnectionRow> createState() => _ConnectionRowState();
}

class _ConnectionRowState extends State<_ConnectionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final conn = widget.conn;
    final muted = monoStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.mutedForeground);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(widget.showApp ? 14 : 56, 9, 14, 9),
          decoration: BoxDecoration(
            color: _hovered ? palette.surfaceHeader : null,
            border: widget.first
                ? null
                : Border(top: BorderSide(color: palette.divider)),
          ),
          child: Row(
            children: [
              if (widget.showApp) ...[
                _AppTile(conn.appName ?? _kUnknownApp),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conn.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                    if (widget.showApp)
                      Text(
                        conn.appName ?? _kUnknownApp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted.copyWith(fontSize: 12),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RouteChip(conn.outboundKind),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(formatDuration(conn.durationAt(widget.now)),
                    style: muted),
              ),
              SizedBox(
                width: 170,
                child: Text(
                  '↑ ${formatBytes(conn.upload)}  ↓ ${formatBytes(conn.download)}',
                  textAlign: TextAlign.right,
                  style: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Панель деталей соединения. Следит за живым списком соединений: байты и
/// длительность обновляются, а закрытое соединение помечается, но панель не
/// пропадает из-под курсора.
class _ConnectionDrawer extends StatefulWidget {
  const _ConnectionDrawer({required this.initial, required this.connections});

  final ConnectionInfo initial;
  final ValueListenable<List<ConnectionInfo>> connections;

  @override
  State<_ConnectionDrawer> createState() => _ConnectionDrawerState();
}

class _ConnectionDrawerState extends State<_ConnectionDrawer> {
  late ConnectionInfo _conn = widget.initial;
  bool _closed = false;
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    widget.connections.addListener(_sync);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_closed) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    widget.connections.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    ConnectionInfo? fresh;
    for (final c in widget.connections.value) {
      if (c.id == _conn.id) {
        fresh = c;
        break;
      }
    }
    setState(() {
      if (fresh != null) {
        _conn = fresh;
      } else {
        _closed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final c = _conn;
    final dot = switch (c.outboundKind) {
      OutboundKind.proxy => palette.accent,
      OutboundKind.direct => palette.success,
      OutboundKind.block => palette.danger,
    };
    String orDash(String v) => v.isEmpty ? '—' : v;
    final rows = <(String, String, bool)>[
      ('Приложение', c.appName ?? '—', false),
      ('Путь процесса', orDash(c.processPath), true),
      (
        'Сеть',
        '${c.network}${c.sniffedType.isEmpty ? '' : ' / ${c.sniffedType}'}',
        true
      ),
      ('Источник', c.source, true),
      ('Назначение', '${c.destinationIP}:${c.destinationPort}', true),
      ('Домен', orDash(c.host), true),
      ('Цепочка', orDash(c.chainLabel), false),
      ('Правило', orDash(c.rule), true),
      ('Payload', orDash(c.rulePayload), true),
      ('Длительность', formatDuration(c.durationAt(DateTime.now())), true),
      ('Начало', _time(c.start.toLocal()), true),
      ('ID', c.id, true),
    ];
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: kUiFontFamily,
        fontSize: 13,
        color: theme.colorScheme.foreground,
      ),
      child: Container(
        width: 380,
        height: double.infinity,
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border(left: BorderSide(color: palette.panelBorder)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 40,
              offset: Offset(-8, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration:
                            BoxDecoration(color: dot, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _RouteChip(c.outboundKind),
                              if (_closed)
                                Text('соединение закрыто',
                                    style: theme.textTheme.muted
                                        .copyWith(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ShadButton.ghost(
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(LucideIcons.x, size: 18),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _TrafficTile(
                        label: 'Отправлено',
                        value: formatBytes(c.upload),
                        color: palette.accentText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TrafficTile(
                        label: 'Получено',
                        value: formatBytes(c.download),
                        color: palette.successText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SelectionArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      for (final (label, value, mono) in rows)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: palette.divider)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 112,
                                child: Text(label,
                                    style: theme.textTheme.muted
                                        .copyWith(fontSize: 12)),
                              ),
                              Expanded(
                                child: Text(
                                  value,
                                  style: mono
                                      ? monoStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: theme.colorScheme.foreground)
                                      : const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _TrafficTile extends StatelessWidget {
  const _TrafficTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: VergePalette.of(context).surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: monoStyle(fontSize: 15, color: color)),
        ],
      ),
    );
  }
}
