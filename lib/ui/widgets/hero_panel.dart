import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import '../../tunnel/tunnel_controller.dart';
import 'ping_badge.dart';

/// Единая высота табов режима и селекта роутинга — чтобы стояли ровно.
const double _kControlHeight = 40;

class HeroPanel extends StatefulWidget {
  const HeroPanel({super.key, required this.controller});
  final AppController controller;
  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel>
    with SingleTickerProviderStateMixin {
  bool _switchingTun = false;
  bool _pressed = false;
  late final AnimationController _pulse;
  // Тикающий раз в секунду таймер перерисовки аптайма. Сам момент
  // подключения хранится в AppController и переживает смену экранов.
  Timer? _uptimeTimer;

  @override
  void initState() {
    super.initState();
    // Непрерывная пульсация ореола вокруг кнопки, когда VPN активен.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
    _pulse.dispose();
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
    final running = c.status == TunnelStatus.connected;
    final connecting = c.status == TunnelStatus.connecting;
    // В активном состоянии — зелёный (вписан в нейтральную палитру),
    // иначе — основной цвет темы.
    const activeGreen = Color(0xFF16A34A);
    final bg = running ? activeGreen : theme.colorScheme.primary;
    final fg = running
        ? const Color(0xFFFFFFFF)
        : theme.colorScheme.primaryForeground;
    return Column(
      children: [
        _PowerButton(
          running: running,
          connecting: connecting,
          pressed: _pressed,
          pulse: _pulse,
          bg: bg,
          fg: fg,
          activeGreen: activeGreen,
          onTap: _togglePower,
          onHighlight: (v) => setState(() => _pressed = v),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShadBadge(
              backgroundColor: running ? activeGreen : null,
              child: Text(running
                  ? _formatUptime(DateTime.now()
                      .difference(c.connectedAt ?? DateTime.now()))
                  : connecting
                      ? 'Подключение…'
                      : 'VPN отключён'),
            ),
            if (running && c.settings.gstaticPingEnabled) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: c.refreshHeroPing,
                // В TUN честный TCP-пинг ноды не гарантирован (см. комментарий
                // к AppController.refreshHeroPing) — там используем gstatic.
                child: c.settings.tunnelMode == TunnelMode.tun
                    ? PingBadge(
                        loading: c.isPingingGstatic &&
                            c.gstaticPingMs == null &&
                            !c.gstaticPingFailed,
                        latencyMs: c.gstaticPingMs,
                        noInternet: c.gstaticPingFailed,
                      )
                    : PingBadge(
                        loading: c.selectedNode != null &&
                            c.isPinging(c.selectedNode!) &&
                            c.pingFor(c.selectedNode!) == null,
                        latencyMs: c.selectedNode == null
                            ? null
                            : c.pingFor(c.selectedNode!)?.latencyMs,
                        timedOut: c.selectedNode != null &&
                            (c.pingFor(c.selectedNode!)?.timedOut ?? false),
                        error: c.selectedNode != null &&
                            c.pingFor(c.selectedNode!)?.error != null,
                        noInternet: c.gstaticPingFailed,
                      ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Режим и роутинг на одном уровне — экономит вертикальное место.
        // Обе контролки жёстко приведены к одной высоте: у ShadTabs и ShadSelect
        // разные внутренние отступы, из-за чего без явной высоты селект выше.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
              height: _kControlHeight,
              child: ShadTabs<TunnelMode>(
                value: c.settings.tunnelMode,
                // Контента у табов нет — зазор под него только переполнял бы
                // фиксированную высоту строки.
                gap: 0,
                onChanged: _switchingTun ? (_) {} : _selectMode,
                tabs: [
                  ShadTab(
                    value: TunnelMode.systemProxy,
                    leading: const Icon(LucideIcons.globe, size: 16),
                    child: const Text('Proxy'),
                  ),
                  ShadTab(
                    value: TunnelMode.tun,
                    leading: const Icon(LucideIcons.network, size: 16),
                    child: const Text('TUN'),
                  ),
                ],
              ),
              ),
            ),
            if (c.routingProfiles.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: SizedBox(
                  height: _kControlHeight,
                  child: ShadSelect<String>(
                  minWidth: 180,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  placeholder: const Text('Роутинг'),
                  initialValue: c.activeRoutingProfileId,
                  options: [
                    for (final p in c.routingProfiles)
                      ShadOption(value: p.id, child: Text(p.name)),
                  ],
                  selectedOptionBuilder: (ctx, value) {
                    for (final p in c.routingProfiles) {
                      if (p.id == value) return Text(p.name);
                    }
                    return const Text('');
                  },
                  onChanged: (id) {
                    if (id != null) c.selectRoutingProfile(id);
                  },
                ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Круглая кнопка питания с анимацией: пульсирующий ореол в активном
/// состоянии, вращающееся кольцо при подключении и мягкое сжатие при нажатии.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.running,
    required this.connecting,
    required this.pressed,
    required this.pulse,
    required this.bg,
    required this.fg,
    required this.activeGreen,
    required this.onTap,
    required this.onHighlight,
  });

  final bool running;
  final bool connecting;
  final bool pressed;
  final AnimationController pulse;
  final Color bg;
  final Color fg;
  final Color activeGreen;
  final VoidCallback onTap;
  final ValueChanged<bool> onHighlight;

  @override
  Widget build(BuildContext context) {
    const size = 92.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onTapDown: (_) => onHighlight(true),
        onTapUp: (_) => onHighlight(false),
        onTapCancel: () => onHighlight(false),
        child: SizedBox(
          width: 132,
          height: 132,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Пульсирующие ореолы только когда активно.
                  if (running) ...[
                    _halo(size, activeGreen, pulse.value),
                    _halo(size, activeGreen, (pulse.value + 0.5) % 1.0),
                  ],
                  // Вращающееся кольцо при подключении.
                  if (connecting)
                    Transform.rotate(
                      angle: pulse.value * 6.28318,
                      child: CustomPaint(
                        size: const Size(size + 12, size + 12),
                        painter: _ArcPainter(bg),
                      ),
                    ),
                  child!,
                ],
              );
            },
            child: AnimatedScale(
              scale: pressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bg,
                  boxShadow: [
                    BoxShadow(
                      color: bg.withValues(alpha: running ? 0.45 : 0.25),
                      blurRadius: running ? 28 : 14,
                      spreadRadius: running ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(LucideIcons.power, size: 30, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _halo(double base, Color color, double t) {
    // t 0→1: кольцо расширяется и растворяется.
    final scale = 1.0 + t * 0.42;
    return Opacity(
      opacity: (1.0 - t) * 0.5,
      child: Container(
        width: base * scale,
        height: base * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

/// Дуга-«спиннер» для состояния подключения.
class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    // Дуга ~270°.
    canvas.drawArc(rect.deflate(2), 0, 4.71238, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
