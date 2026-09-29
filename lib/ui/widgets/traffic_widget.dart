import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/connection_info.dart';
import '../../services/byte_format.dart';
import '../../theme/app_theme.dart';
import '../../theme/verge_palette.dart';

/// Живой счётчик внизу сайдбара: мгновенная скорость и суммарно за сессию.
/// Некликабельный — отдельного экрана статистики нет.
class TrafficWidget extends StatelessWidget {
  const TrafficWidget({super.key, required this.stats});
  final TrafficStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            context,
            icon: LucideIcons.arrowDown,
            tint: palette.successText,
            tile: palette.success.withValues(alpha: 0.14),
            speed: formatSpeed(stats.downSpeed),
            total: formatBytes(stats.downTotal),
          ),
          const SizedBox(height: 6),
          _row(
            context,
            icon: LucideIcons.arrowUp,
            tint: palette.accentText,
            tile: palette.accent.withValues(alpha: 0.14),
            speed: formatSpeed(stats.upSpeed),
            total: formatBytes(stats.upTotal),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required Color tile,
    required String speed,
    required String total,
  }) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 12, color: tint),
        ),
        const SizedBox(width: 8),
        // Скорость и итог в своих колонках — стрелки не прыгают при смене
        // разрядности значений.
        Expanded(
          child: Text(
            speed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: monoStyle(color: theme.colorScheme.foreground),
          ),
        ),
        Text(
          total,
          maxLines: 1,
          style: theme.textTheme.muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
