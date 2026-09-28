import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import '../../services/node_display.dart';
import '../../theme/verge_palette.dart';
import '../../tunnel/tunnel_controller.dart';
import 'paper.dart';

/// Карточка подключения: тумблер, статус и сервер, режим и роутинг, под ней —
/// плитки времени и задержки.
class HeroPanel extends StatefulWidget {
  const HeroPanel({super.key, required this.controller});
  final AppController controller;
  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  bool _switchingTun = false;
  // Тикающий раз в секунду таймер перерисовки аптайма. Сам момент
  // подключения хранится в AppController и переживает смену экранов.
  Timer? _uptimeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStatusChanged);
    _onStatusChanged();
  }

  @override
  void didUpdateWidget(HeroPanel old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onStatusChanged);
      widget.controller.addListener(_onStatusChanged);
      _onStatusChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStatusChanged);
    _uptimeTimer?.cancel();
    super.dispose();
  }

  void _onStatusChanged() {
    final running = widget.controller.status == TunnelStatus.connected;
    if (running && _uptimeTimer == null) {
      _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _uptimeTimer != null) {
      _uptimeTimer!.cancel();
      _uptimeTimer = null;
    }
    // Бейдж пинга и текст статуса зависят от контроллера — перерисовываемся
    // на каждое изменение, а не только на секундном тике аптайма.
    if (mounted) setState(() {});
  }

  /// «MM:SS», «H:MM:SS», «Dд H:MM:SS» — без ведущих нулей у старшего разряда.
  static String _formatUptime(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final days = s ~/ 86400;
    final hours = (s % 86400) ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final seconds = s % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    // ignore: unnecessary_brace_in_string_interps — скобки нужны: «д» слипается.
    if (days > 0) return '${days}д $hours:$mm:$ss';
    if (hours > 0) return '$hours:$mm:$ss';
    return '$mm:$ss';
  }

  Future<void> _togglePower() async {
    final c = widget.controller;
    if (c.status == TunnelStatus.connected ||
        c.status == TunnelStatus.connecting) {
      await c.disconnect();
    } else {
      await c.connect();
    }
  }

  Future<void> _selectMode(TunnelMode mode) async {
    final c = widget.controller;
    if (mode == c.settings.tunnelMode) return;
    if (mode == TunnelMode.systemProxy) {
      await c.updateSettings(
          c.settings.copyWith(tunnelMode: TunnelMode.systemProxy));
      return;
    }
    setState(() => _switchingTun = true);
    await c.requestTunMode();
    if (mounted) setState(() => _switchingTun = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final running = c.status == TunnelStatus.connected;
    final connecting = c.status == TunnelStatus.connecting;

    final (cardBg, cardBorder, titleColor, title) = running
        ? (palette.successSoft, palette.successBorder, palette.successText,
            'Подключено')
        : connecting
            ? (palette.warningSoft, palette.warningBorder, palette.warningText,
                'Подключаемся…')
            : (palette.surfaceHeader, palette.panelBorder,
                theme.colorScheme.foreground, 'Не подключено');

    final node = c.selectedNode;
    final nodeName = node == null ? null : splitCountryFlag(node.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              ConnectToggle(
                running: running,
                connecting: connecting,
                onTap: _togglePower,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (nodeName?.code != null) ...[
                          CountryChip(nodeName!.code!),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            nodeName == null
                                ? 'Выберите сервер ниже'
                                : [
                                    nodeName.name,
                                    if (c.activeProfile != null)
                                      c.activeProfile!.name,
                                  ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 236,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Segmented<TunnelMode>(
                      value: c.settings.tunnelMode,
                      onChanged: _switchingTun ? null : _selectMode,
                      options: const [
                        SegmentedOption(
                          value: TunnelMode.systemProxy,
                          label: 'Прокси',
                          icon: LucideIcons.globe,
                        ),
                        SegmentedOption(
                          value: TunnelMode.tun,
                          label: 'TUN',
                          icon: LucideIcons.network,
                        ),
                      ],
                    ),
                    if (c.routingProfiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _RoutingSelect(controller: c),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Скорость загрузки и отдачи — в сайдбаре, здесь не дублируем.
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Время',
                child: Text(running
                    ? _formatUptime(DateTime.now()
                        .difference(c.connectedAt ?? DateTime.now()))
                    : '—'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Задержка',
                child: running && c.settings.gstaticPingEnabled
                    ? _heroPing(context, c)
                    : const Text('—'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Пинг до ноды — простым моно-текстом, как «Время» рядом: в TUN он
  /// меряется мимо туннеля (см. AppController.refreshHeroPing), поэтому
  /// честен в обоих режимах. gstatic остаётся признаком «есть ли интернет».
  /// Тап — перезамер.
  Widget _heroPing(BuildContext context, AppController c) {
    final palette = VergePalette.of(context);
    final node = c.selectedNode;
    final res = node == null ? null : c.pingFor(node);
    final Widget value;
    if (node != null && c.isPinging(node) && res == null) {
      value = Spinner(
          size: 14, color: ShadTheme.of(context).colorScheme.mutedForeground);
    } else if (c.gstaticPingFailed) {
      value = Text('нет интернета', style: TextStyle(color: palette.dangerText));
    } else if (res != null && (res.timedOut || res.error != null)) {
      value = Text(res.timedOut ? 'таймаут' : 'ошибка',
          style: TextStyle(color: palette.dangerText));
    } else if (res?.latencyMs != null) {
      final ms = res!.latencyMs!;
      value = Text('$ms мс', style: TextStyle(color: palette.latencyText(ms)));
    } else {
      value = const Text('—');
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: c.refreshHeroPing,
        child: value,
      ),
    );
  }
}

class _RoutingSelect extends StatelessWidget {
  const _RoutingSelect({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = ShadTheme.of(context);
    String nameOf(String id) {
      for (final p in c.routingProfiles) {
        if (p.id == id) return p.name;
      }
      return '';
    }

    return SizedBox(
      height: 38,
      child: ShadSelect<String>(
        minWidth: 236,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        placeholder: const Text('Правила роутинга'),
        initialValue: c.activeRoutingProfileId,
        options: [
          for (final p in c.routingProfiles)
            ShadOption(value: p.id, child: Text(p.name)),
        ],
        selectedOptionBuilder: (ctx, value) => Row(
          children: [
            Icon(LucideIcons.route,
                size: 14, color: theme.colorScheme.mutedForeground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(nameOf(value),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        onChanged: (id) {
          if (id != null) c.selectRoutingProfile(id);
        },
      ),
    );
  }
}

/// Большой тумблер подключения. Три состояния: выключен (ручка слева),
/// подключение (посередине, янтарный), подключён (справа, зелёный).
class ConnectToggle extends StatefulWidget {
  const ConnectToggle({
    super.key,
    required this.running,
    required this.connecting,
    required this.onTap,
    this.scale = 1,
  });

  final bool running;
  final bool connecting;
  final VoidCallback onTap;

  /// Масштаб: 1 — карточка на главной, меньше — мини-окно трея.
  final double scale;

  @override
  State<ConnectToggle> createState() => _ConnectToggleState();
}

class _ConnectToggleState extends State<ConnectToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    final dark = ShadTheme.of(context).brightness == Brightness.dark;
    final running = widget.running;
    final connecting = widget.connecting;
    final track = running
        ? palette.success
        : connecting
            ? palette.warningTrack
            : palette.idleTrack;
    final knobFg = running
        ? palette.successText
        : connecting
            ? palette.warningText
            : palette.navForeground;
    final align = running
        ? Alignment.centerRight
        : connecting
            ? Alignment.center
            : Alignment.centerLeft;
    // В тёмной теме выключенная ручка приглушена, иначе она светит ярче
    // всего экрана.
    final knob = !running && !connecting && dark
        ? const Color(0xFFC9C5BB)
        : const Color(0xFFFFFFFF);

    return Semantics(
      toggled: running,
      button: true,
      label: running || connecting ? 'Отключиться' : 'Подключиться',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 96 * widget.scale,
              height: 54 * widget.scale,
              padding: EdgeInsets.all(5 * widget.scale),
              decoration: BoxDecoration(
                color: track,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                alignment: align,
                child: Container(
                  width: 44 * widget.scale,
                  height: 44 * widget.scale,
                  decoration: BoxDecoration(
                    color: knob,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.power,
                      size: 18 * widget.scale, color: knobFg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
