import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../theme/verge_palette.dart';

/// Ненавязчивая полоска о новой версии. Модального диалога намеренно нет:
/// обновление не должно перегораживать запуск приложения.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.updateToOffer;
    if (info == null) return const SizedBox.shrink();
    final palette = VergePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        border: Border(bottom: BorderSide(color: palette.accentSoftBorder)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleArrowUp, size: 16, color: palette.accentText),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Доступна версия ${info.version}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: palette.accentText)),
          ),
          ShadButton(
            size: ShadButtonSize.sm,
            backgroundColor: palette.accent,
            foregroundColor: const Color(0xFFFFFFFF),
            onPressed: () => controller.downloadAndInstallUpdate(),
            child: const Text('Обновить'),
          ),
          const SizedBox(width: 8),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: controller.dismissUpdateBanner,
            child: const Text('Позже'),
          ),
          const SizedBox(width: 4),
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
