import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/node_engine.dart';
import '../../theme/app_colors.dart';

/// Двухбуквенный индикатор движка ноды. Чистый presentational-виджет.
///
/// У неактивных нод показывает ПЛАН (на чём нода будет запущена), у активной
/// подключённой — ФАКТ. Расходятся они только после отката, и ровно там факт
/// и важен: иначе автофолбэк остаётся полностью немым.
class EngineBadge extends StatelessWidget {
  final NodeEngine engine;

  /// Движок зафиксирован пользователем, а не выбран автоматикой.
  final bool manual;

  /// Планировался Xray, но пришлось откатиться на sing-box.
  final bool fellBack;

  const EngineBadge({
    super.key,
    required this.engine,
    this.manual = false,
    this.fellBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final label = engine == NodeEngine.xray ? 'XR' : 'SB';
    // Откат — единственное состояние, которое подсвечиваем тревожным цветом:
    // пользователь получил не тот движок, который планировался.
    final accent = fellBack ? AppColors.pingBad : null;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: manual ? (accent ?? scheme.primary) : null,
        border: manual
            ? null
            : Border.all(color: accent ?? scheme.border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: manual
              ? scheme.primaryForeground
              : (accent ?? scheme.mutedForeground),
        ),
      ),
    );

    final message = fellBack
        ? 'Xray не запустился, работаем на sing-box'
        : (manual ? 'Движок выбран вручную' : 'Движок выбран автоматически');
    return Tooltip(message: message, child: badge);
  }
}
