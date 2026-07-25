import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Бейдж задержки пинга. Чистый presentational-виджет.
class PingBadge extends StatelessWidget {
  final bool loading;
  final int? latencyMs;
  final bool timedOut;
  final bool error;

  const PingBadge({
    super.key,
    this.loading = false,
    this.latencyMs,
    this.timedOut = false,
    this.error = false,
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
    if (latencyMs != null) {
      return Text('$latencyMs мс',
          style: TextStyle(
              color: AppColors.pingColor(latencyMs!),
              fontWeight: FontWeight.w600));
    }
    if (timedOut) {
      return Text('таймаут', style: TextStyle(color: AppColors.pingBad));
    }
    if (error) {
      return Text('ошибка', style: TextStyle(color: AppColors.pingBad));
    }
    return const SizedBox.shrink();
  }
}
