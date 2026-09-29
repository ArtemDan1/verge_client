import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../app/app_controller.dart';
import '../app/tray_popover_controller.dart';
import '../models/app_settings.dart';
import '../models/connection_info.dart';
import '../services/byte_format.dart';
import '../services/node_display.dart';
import '../theme/app_theme.dart';
import '../theme/verge_palette.dart';
import '../tunnel/tunnel_controller.dart';
import 'widgets/hero_panel.dart' show ConnectToggle;
import 'widgets/paper.dart';

/// Мини-окно трея: тумблер со статусом, сервера активного профиля, режим и
/// переход в главное окно.
class TrayPopover extends StatefulWidget {
  const TrayPopover({
    super.key,
    required this.controller,
    required this.popover,
  });

  final AppController controller;
  final TrayPopoverController popover;

  static const _headerHeight = 76.0;
  static const _labelHeight = 30.0;
  static const _rowHeight = 40.0;
  static const _footerHeight = 58.0;
  static const _maxRows = 6;

  /// Высота окна под текущий профиль: список серверов без прокрутки, если
  /// их немного, иначе — [_maxRows] строк и прокрутка.
  static double heightFor(AppController c) {
    final nodes = c.activeProfile?.nodes.length ?? 0;
    final rows = nodes == 0 ? 1.5 : math.min(nodes, _maxRows).toDouble();
    return _headerHeight +
        _labelHeight +
        rows * _rowHeight +
        16 +
        _footerHeight;
  }

  @override
  State<TrayPopover> createState() => _TrayPopoverState();
}

class _TrayPopoverState extends State<TrayPopover> {
  Timer? _ticker;
  bool _switchingTun = false;

  AppController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    // Аптайм в шапке тикает раз в секунду, пока окно открыто.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && c.status == TunnelStatus.connected) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (c.status == TunnelStatus.connected ||
        c.status == TunnelStatus.connecting) {
      await c.disconnect();
    } else {
      await c.connect();
    }
  }

  Future<void> _selectMode(TunnelMode mode) async {
    if (mode == c.settings.tunnelMode) return;
    if (mode == TunnelMode.systemProxy) {
      await c.updateSettings(
        c.settings.copyWith(tunnelMode: TunnelMode.systemProxy),
      );
      return;
    }
    setState(() => _switchingTun = true);
    await c.requestTunMode();
    if (mounted) setState(() => _switchingTun = false);
  }

  static String _uptime(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = s ~/ 3600;
    final mm = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            widget.popover.close(),
      },
      child: Focus(
        autofocus: true,
        // Главный экран получает стиль текста от Scaffold, а мини-окно рисуется
        // без него — задаём шрифт и цвет явно.
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: kUiFontFamily,
            fontFamilyFallback: kEmojiFontFallback,
            fontSize: 14,
            color: ShadTheme.of(context).colorScheme.foreground,
          ),
          child: ColoredBox(
            color: palette.panel,
            child: AnimatedBuilder(
              animation: c,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  Expanded(child: _servers(context)),
                  _footer(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final running = c.status == TunnelStatus.connected;
    final connecting = c.status == TunnelStatus.connecting;
    final (bg, border, titleColor, title) = running
        ? (
            palette.successSoft,
            palette.successBorder,
            palette.successText,
            'Подключено',
          )
        : connecting
        ? (
            palette.warningSoft,
            palette.warningBorder,
            palette.warningText,
            'Подключаемся…',
          )
        : (
            palette.surfaceHeader,
            palette.panelBorder,
            theme.colorScheme.foreground,
            'Не подключено',
          );
    return Container(
      height: TrayPopover._headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          ConnectToggle(
            running: running,
            connecting: connecting,
            onTap: _toggle,
            scale: 0.6,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (running)
                  ValueListenableBuilder<TrafficStats>(
                    valueListenable: c.traffic,
                    builder: (context, t, _) => Text(
                      '${_uptime(DateTime.now().difference(c.connectedAt ?? DateTime.now()))}'
                      '  ·  ↓ ${formatSpeed(t.downSpeed)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: monoStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  )
                else
                  Text(
                    connecting ? 'Проверяем сервер' : 'Нажмите, чтобы подключиться',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Меню у значка трея нет — выход живёт здесь. На Windows крестик
          // только прячет окно, так что это единственный способ закрыть Verge.
          ShadTooltip(
            builder: (_) => const Text('Выйти из Verge'),
            child: ShadButton.ghost(
              width: 32,
              height: 32,
              padding: EdgeInsets.zero,
              onPressed: widget.popover.quit,
              child: Icon(
                LucideIcons.logOut,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servers(BuildContext context) {
    final theme = ShadTheme.of(context);
    final profile = c.activeProfile;
    final label = theme.textTheme.muted.copyWith(fontSize: 12);
    if (profile == null || profile.nodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            profile == null
                ? 'Нет подписок — добавьте их в главном окне'
                : 'В подписке нет серверов',
            textAlign: TextAlign.center,
            style: label,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: TrayPopover._labelHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Сервер · ${profile.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: profile.nodes.length,
              itemExtent: TrayPopover._rowHeight,
              itemBuilder: (context, i) {
                final node = profile.nodes[i];
                final ping = c.pingFor(node);
                return _ServerRow(
                  name: node.name,
                  selected:
                      profile.selectedNodeIndex == i &&
                      profile.id == c.activeProfileId,
                  latencyMs: ping?.latencyMs,
                  failed: ping != null && ping.latencyMs == null,
                  onTap: () => c.selectNode(profile.id, i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final palette = VergePalette.of(context);
    return Container(
      height: TrayPopover._footerHeight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Segmented<TunnelMode>(
              value: c.settings.tunnelMode,
              height: 34,
              onChanged: _switchingTun ? null : _selectMode,
              options: const [
                SegmentedOption(value: TunnelMode.systemProxy, label: 'Прокси'),
                SegmentedOption(value: TunnelMode.tun, label: 'TUN'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: widget.popover.openMain,
            child: const Text('Открыть Verge'),
          ),
        ],
      ),
    );
  }
}

class _ServerRow extends StatefulWidget {
  const _ServerRow({
    required this.name,
    required this.selected,
    required this.latencyMs,
    required this.failed,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final int? latencyMs;
  final bool failed;
  final VoidCallback onTap;

  @override
  State<_ServerRow> createState() => _ServerRowState();
}

class _ServerRowState extends State<_ServerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radioOn = dark ? palette.accentText : palette.accent;
    final name = splitCountryFlag(widget.name);
    final ms = widget.latencyMs;
    final (latency, latencyColor) = ms != null
        ? ('$ms мс', palette.latencyText(ms))
        : widget.failed
        ? ('нет ответа', palette.dangerText)
        : ('—', theme.colorScheme.mutedForeground);
    final bg = widget.selected
        ? palette.accentSoft
        : palette.surface.withValues(alpha: _hovered ? 1 : 0);
    return Semantics(
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.selected ? radioOn : palette.radioOff,
                      width: widget.selected ? 5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (name.code != null) ...[
                  CountryChip(name.code!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  latency,
                  style: monoStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: latencyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
