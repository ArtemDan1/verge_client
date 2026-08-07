import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import '../../theme/app_colors.dart';

/// Бейдж задержки пинга.
///
/// Приоритет состояний: [loading] > [noInternet] (без интернета цифра пинга
/// до ноды ни о чём не говорит) > [timedOut]/[error] (нода недоступна) >
/// [latencyMs] > пусто.
class PingBadge extends StatefulWidget {
  final bool loading;
  final int? latencyMs;
  final bool timedOut;
  final bool error;
  final bool noInternet;

  /// Клик по чипу (перезамер). null — чип некликабелен и не подсвечивается.
  final VoidCallback? onTap;

  const PingBadge({
    super.key,
    this.loading = false,
    this.latencyMs,
    this.timedOut = false,
    this.error = false,
    this.noInternet = false,
    this.onTap,
  });

  @override
  State<PingBadge> createState() => _PingBadgeState();
}

class _PingBadgeState extends State<PingBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final chip = _content(context);
    if (widget.onTap == null) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: chip),
    );
  }

  Widget _content(BuildContext context) {
    final loading = widget.loading;
    final timedOut = widget.timedOut;
    final error = widget.error;
    final noInternet = widget.noInternet;
    final latencyMs = widget.latencyMs;
    if (loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (noInternet) {
      return _chip(
        color: AppColors.pingBad,
        icon: LucideIcons.triangleAlert,
        label: 'нет интернета',
      );
    }
    if (timedOut || error) {
      return _chip(
        color: AppColors.pingBad,
        icon: LucideIcons.triangleAlert,
        label: timedOut ? 'таймаут' : 'ошибка',
      );
    }
    if (latencyMs != null) {
      return _chip(
          color: AppColors.pingColor(latencyMs), label: '$latencyMs мс');
    }
    return const SizedBox.shrink();
  }

  // Паддинг/шрифт совпадают с ShadBadge (primaryBadgeTheme): horizontal 10,
  // vertical 2, fontSize 12, height 16/12 — чтобы чип пинга был того же
  // размера, что соседний бейдж времени работы.
  Widget _chip({required Color color, IconData? icon, required String label}) {
    // Наведение осветляет заливку — тот же приём, что у остальных чипов и
    // кнопок: без него кликабельный чип выглядит статичной подписью.
    final bg = _hovered ? Color.alphaBlend(Colors.white24, color) : color;
    return AnimatedContainer(
      key: const Key('pingBadgeChip'),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 16 / 12,
              )),
        ],
      ),
    );
  }
}
