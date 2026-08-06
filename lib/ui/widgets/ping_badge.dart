import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import '../../theme/app_colors.dart';

/// Бейдж задержки пинга. Чистый presentational-виджет.
///
/// Приоритет состояний: [loading] > [timedOut]/[error] (нода недоступна) >
/// [noInternet] (нода отвечает, но интернета через туннель нет) >
/// [latencyMs] > пусто.
class PingBadge extends StatelessWidget {
  final bool loading;
  final int? latencyMs;
  final bool timedOut;
  final bool error;
  final bool noInternet;

  const PingBadge({
    super.key,
    this.loading = false,
    this.latencyMs,
    this.timedOut = false,
    this.error = false,
    this.noInternet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (timedOut || error) {
      return _chip(
        color: AppColors.pingBad,
        icon: LucideIcons.triangleAlert,
        label: timedOut ? 'таймаут' : 'ошибка',
      );
    }
    if (noInternet) {
      return _chip(
        color: AppColors.pingBad,
        icon: LucideIcons.triangleAlert,
        label: 'нет интернета',
      );
    }
    if (latencyMs != null) {
      return _chip(
          color: AppColors.pingColor(latencyMs!), label: '$latencyMs мс');
    }
    return const SizedBox.shrink();
  }

  // Паддинг/шрифт совпадают с ShadBadge (primaryBadgeTheme): horizontal 10,
  // vertical 2, fontSize 12, height 16/12 — чтобы чип пинга был того же
  // размера, что соседний бейдж времени работы.
  Widget _chip({required Color color, IconData? icon, required String label}) {
    return Container(
      key: const Key('pingBadgeChip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
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
