import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../app/app_controller.dart';
import '../models/connection_info.dart';
import '../services/byte_format.dart';
import '../tunnel/tunnel_controller.dart';

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
  OutboundKind.direct: 'direct',
  OutboundKind.proxy: 'proxy',
  OutboundKind.block: 'block',
};

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _search = TextEditingController();
  final _kinds = <OutboundKind>{};
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            controller: _search,
            placeholder: const Text('Поиск: домен, IP или приложение'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final k in OutboundKind.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ShadButton.outline(
                    size: ShadButtonSize.sm,
                    backgroundColor:
                        _kinds.contains(k) ? theme.colorScheme.accent : null,
                    onPressed: () => setState(() {
                      _kinds.contains(k) ? _kinds.remove(k) : _kinds.add(k);
                    }),
                    child: Text(_kindLabels[k]!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<List<ConnectionInfo>>(
              valueListenable: widget.controller.connections,
              builder: (context, all, _) {
                final list = filterConnections(
                  all,
                  query: _search.text,
                  kinds: _kinds,
                )..sort((a, b) => b.start.compareTo(a.start));
                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      widget.controller.status == TunnelStatus.connected
                          ? 'Нет активных соединений'
                          : 'VPN отключён',
                      style: theme.textTheme.muted,
                    ),
                  );
                }
                if (list.isEmpty) {
                  return Center(
                    child: Text('Ничего не найдено', style: theme.textTheme.muted),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => _ConnectionCard(
                    key: ValueKey(list[i].id),
                    conn: list[i],
                    index: i + 1,
                    now: _now,
                    onTap: () => _showDetails(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(ConnectionInfo c) {
    showShadSheet(
      context: context,
      side: ShadSheetSide.right,
      builder: (ctx) => ShadSheet(
        title: Text(c.title),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('ID', c.id),
              _row('Начало', c.start.toLocal().toString()),
              _row('Длительность', formatDuration(c.durationAt(_now))),
              _row('Приложение', c.appName ?? '—'),
              _row('Путь процесса', c.processPath.isEmpty ? '—' : c.processPath),
              _row('Сеть', '${c.network}${c.sniffedType.isEmpty ? '' : ' / ${c.sniffedType}'}'),
              _row('Источник', c.source),
              _row('Назначение', '${c.destinationIP}:${c.destinationPort}'),
              _row('Домен', c.host.isEmpty ? '—' : c.host),
              _row('Цепочка', c.chainLabel.isEmpty ? '—' : c.chainLabel),
              _row('Правило', c.rule.isEmpty ? '—' : c.rule),
              _row('Payload', c.rulePayload.isEmpty ? '—' : c.rulePayload),
              _row('Отправлено', formatBytes(c.upload)),
              _row('Получено', formatBytes(c.download)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    super.key,
    required this.conn,
    required this.index,
    required this.now,
    required this.onTap,
  });

  final ConnectionInfo conn;
  final int index;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dotColor = switch (conn.outboundKind) {
      OutboundKind.proxy => theme.colorScheme.primary,
      OutboundKind.direct => theme.colorScheme.mutedForeground,
      OutboundKind.block => theme.colorScheme.destructive,
    };
    final app = conn.appName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            ),
            SizedBox(width: 28, child: Text('$index', style: theme.textTheme.muted)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(conn.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(formatDuration(conn.durationAt(now)),
                          style: theme.textTheme.muted),
                    ],
                  ),
                  Text('${conn.source}  ${conn.sniffedType}',
                      style: theme.textTheme.muted),
                  if (app != null) Text(app, style: theme.textTheme.muted),
                  Text(
                    '${conn.network}  ↑ ${formatBytes(conn.upload)} ↓ ${formatBytes(conn.download)}',
                    style: theme.textTheme.muted,
                  ),
                  Text(conn.chainLabel, style: theme.textTheme.muted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(LucideIcons.chevronRight,
                  size: 16, color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
