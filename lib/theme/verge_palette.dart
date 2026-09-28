import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Цвета дизайна «Бумага», которых нет в [ShadColorScheme]: фон окна вокруг
/// панели контента, кобальтовый акцент выбора и мягкие заливки статусов.
///
/// Две фиксированные палитры, выбор — по яркости текущей темы shadcn, поэтому
/// виджетам достаточно `VergePalette.of(context)`.
@immutable
class VergePalette {
  const VergePalette({
    required this.chrome,
    required this.panel,
    required this.panelBorder,
    required this.surface,
    required this.surfaceHeader,
    required this.divider,
    required this.chip,
    required this.chipForeground,
    required this.navActive,
    required this.navActiveRing,
    required this.navForeground,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.accentSoftBorder,
    required this.radioOff,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.successBorder,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.warningBorder,
    required this.warningTrack,
    required this.danger,
    required this.dangerText,
    required this.dangerSoft,
    required this.idleTrack,
  });

  /// Фон окна: сайдбар и поля вокруг панели контента.
  final Color chrome;

  /// «Вставленная» панель контента.
  final Color panel;
  final Color panelBorder;

  /// Плитки статистики, поля поиска.
  final Color surface;

  /// Шапки карточек (профиль, группа соединений).
  final Color surfaceHeader;

  /// Разделители строк внутри карточек.
  final Color divider;

  /// Мелкие чипы (код страны) и дорожки сегментных переключателей.
  final Color chip;
  final Color chipForeground;

  final Color navActive;
  final Color navActiveRing;
  final Color navForeground;

  /// Кобальт для заливок под белым текстом (кнопки, свитчи, бейджи).
  final Color accent;

  /// Кобальт для текста, обводок и радио-кнопок.
  final Color accentText;

  /// Подложка выбранной строки / активной карточки.
  final Color accentSoft;
  final Color accentSoftBorder;

  final Color radioOff;

  final Color success;
  final Color successText;
  final Color successSoft;
  final Color successBorder;

  final Color warning;
  final Color warningText;
  final Color warningSoft;
  final Color warningBorder;
  final Color warningTrack;

  final Color danger;
  final Color dangerText;
  final Color dangerSoft;

  /// Дорожка выключенного тумблера подключения.
  final Color idleTrack;

  static const light = VergePalette(
    chrome: Color(0xFFEFEDE7),
    panel: Color(0xFFFFFFFF),
    panelBorder: Color(0xFFE4E2DB),
    surface: Color(0xFFF6F5F1),
    surfaceHeader: Color(0xFFFBFAF7),
    divider: Color(0xFFF0EEE8),
    chip: Color(0xFFF0EEE8),
    chipForeground: Color(0xFF3D3B35),
    navActive: Color(0xFFFFFFFF),
    navActiveRing: Color(0xFFE4E2DB),
    navForeground: Color(0xFF55524A),
    accent: Color(0xFF2E5BFF),
    accentText: Color(0xFF2447D6),
    accentSoft: Color(0xFFF2F5FF),
    accentSoftBorder: Color(0xFFD6DFFF),
    radioOff: Color(0xFFCFCBC1),
    success: Color(0xFF1F9D55),
    successText: Color(0xFF177A42),
    successSoft: Color(0xFFF3FAF6),
    successBorder: Color(0xFFCDEBD9),
    warning: Color(0xFFD97706),
    warningText: Color(0xFFB45309),
    warningSoft: Color(0xFFFFF8EE),
    warningBorder: Color(0xFFF4DDB6),
    warningTrack: Color(0xFFF0C27A),
    danger: Color(0xFFC2410C),
    dangerText: Color(0xFFB42318),
    dangerSoft: Color(0xFFFDE4DE),
    idleTrack: Color(0xFFD9D6CE),
  );

  /// Тёмная «бумага» — тёплый графит, а не холодный чёрный.
  static const dark = VergePalette(
    chrome: Color(0xFF161513),
    panel: Color(0xFF1E1D1A),
    panelBorder: Color(0xFF2D2B27),
    surface: Color(0xFF262420),
    surfaceHeader: Color(0xFF22211D),
    divider: Color(0xFF282622),
    chip: Color(0xFF2D2B27),
    chipForeground: Color(0xFFD6D2C8),
    navActive: Color(0xFF26241F),
    navActiveRing: Color(0xFF34322D),
    navForeground: Color(0xFFB3AFA5),
    accent: Color(0xFF4169FF),
    accentText: Color(0xFF8FA8FF),
    accentSoft: Color(0xFF1F2438),
    accentSoftBorder: Color(0xFF323C66),
    radioOff: Color(0xFF4A4740),
    success: Color(0xFF2FB36B),
    successText: Color(0xFF6FD69B),
    successSoft: Color(0xFF18251D),
    successBorder: Color(0xFF25402F),
    warning: Color(0xFFE09B3D),
    warningText: Color(0xFFF0B45A),
    warningSoft: Color(0xFF261F15),
    warningBorder: Color(0xFF4A3A1E),
    warningTrack: Color(0xFF8A6424),
    danger: Color(0xFFE0553A),
    dangerText: Color(0xFFFF917C),
    dangerSoft: Color(0xFF3D2019),
    idleTrack: Color(0xFF3A3832),
  );

  static VergePalette of(BuildContext context) =>
      ShadTheme.of(context).brightness == Brightness.dark ? dark : light;

  /// Цвет полоски задержки: те же пороги, что у [AppColors.pingColor].
  Color latencyBar(int ms) => ms < 150
      ? success
      : ms < 400
          ? warning
          : danger;

  /// Цвет подписи задержки — темнее полоски, чтобы текст читался.
  Color latencyText(int ms) => ms < 150
      ? successText
      : ms < 400
          ? warningText
          : dangerText;
}
