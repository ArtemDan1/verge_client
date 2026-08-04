import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';

/// Ненавязчивая полоска о новой версии. Модального диалога намеренно нет:
/// обновление не должно перегораживать запуск приложения.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.updateToOffer;
    if (info == null) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.accent,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.arrowUpCircle, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Доступна версия ${info.version}',
                overflow: TextOverflow.ellipsis),
          ),
          ShadButton(
            size: ShadButtonSize.sm,
            onPressed: () => controller.downloadAndInstallUpdate(),
            child: const Text('Обновить'),
          ),
          const SizedBox(width: 8),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: controller.dismissUpdateBanner,
            child: const Text('Позже'),
          ),
          const SizedBox(width: 8),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => controller.skipUpdateVersion(),
            child: const Text('Пропустить версию'),
          ),
        ],
      ),
    );
  }
}
