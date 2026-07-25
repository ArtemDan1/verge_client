import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/connection_info.dart';
import '../../services/byte_format.dart';

/// Живой счётчик внизу сайдбара: мгновенная скорость и суммарно за сессию.
/// Некликабельный — отдельного экрана статистики нет.
class TrafficWidget extends StatelessWidget {
  const TrafficWidget({super.key, required this.stats});
  final TrafficStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted;
    final small = theme.textTheme.small;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: theme.radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Каждая метрика в равной по ширине половине строки — иначе стрелка ↓
          // сдвигается при смене разрядности значения слева.
          _row(context, '↑ ${formatSpeed(stats.upSpeed)}',
              '↓ ${formatSpeed(stats.downSpeed)}', small),
          const SizedBox(height: 2),
          _row(context, '↑ ${formatBytes(stats.upTotal)}',
              '↓ ${formatBytes(stats.downTotal)}', muted),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String left, String right, TextStyle? style) {
    return Row(
      children: [
        Expanded(
          child: Text(left,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: Text(right,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
