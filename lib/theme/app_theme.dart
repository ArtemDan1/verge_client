import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'verge_palette.dart';

/// Запасной шрифт для emoji — прежде всего для флагов стран в именах нод.
///
/// В системном шрифте Windows глифов флагов нет, и пара regional indicator
/// («🇫🇷» = U+1F1EB U+1F1F7) отрисовывается как буквы «FR». Бандленный Noto
/// закрывает эту дыру. Основным шрифтом он быть не может — латиницы в нём нет,
/// только emoji, поэтому идёт исключительно в fontFamilyFallback.
///
/// На macOS фолбэк безвреден: там флаги есть в системном шрифте, и до Noto
/// очередь не доходит.
const List<String> kEmojiFontFallback = ['NotoColorEmoji'];

/// Основной шрифт интерфейса. Бандлится (assets/fonts): системные шрифты
/// macOS и Windows слишком разные, а дизайн рассчитан на одну гарнитуру.
/// Кириллица в Onest есть.
const String kUiFontFamily = 'Onest';

/// Моноширинный шрифт для логов, чисел и JSON-редактора. Бандлится, поэтому
/// системные семейства остаются только запасом на случай битого ассета.
const String kMonoFontFamily = 'JetBrains Mono';
const List<String> kMonoFontFallback = [
  'SF Mono',
  'Menlo',
  'Consolas',
  'Cascadia Mono',
  'Courier New',
  'monospace',
];

/// Стиль моноширинных цифр (таймер, скорость, пинг).
TextStyle monoStyle({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
}) =>
    TextStyle(
      fontFamily: kMonoFontFamily,
      fontFamilyFallback: kMonoFontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

/// Цветовая схема «Бумага»: тёплые нейтральные, чернильный primary.
/// Кобальтовый акцент и статусы живут в [VergePalette].
class VergeColorScheme extends ShadColorScheme {
  const VergeColorScheme.light()
      : super(
          background: const Color(0xFFFFFFFF),
          foreground: const Color(0xFF1C1B18),
          card: const Color(0xFFFFFFFF),
          cardForeground: const Color(0xFF1C1B18),
          popover: const Color(0xFFFFFFFF),
          popoverForeground: const Color(0xFF1C1B18),
          primary: const Color(0xFF1C1B18),
          primaryForeground: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFF0EEE8),
          secondaryForeground: const Color(0xFF1C1B18),
          muted: const Color(0xFFF6F5F1),
          mutedForeground: const Color(0xFF6B6860),
          accent: const Color(0xFFF0EEE8),
          accentForeground: const Color(0xFF1C1B18),
          destructive: const Color(0xFFB42318),
          destructiveForeground: const Color(0xFFFFFFFF),
          border: const Color(0xFFE4E2DB),
          input: const Color(0xFFE4E2DB),
          ring: const Color(0xFF2E5BFF),
          selection: const Color(0xFFD6DFFF),
        );

  const VergeColorScheme.dark()
      : super(
          background: const Color(0xFF1E1D1A),
          foreground: const Color(0xFFEDEBE5),
          card: const Color(0xFF1E1D1A),
          cardForeground: const Color(0xFFEDEBE5),
          popover: const Color(0xFF22211D),
          popoverForeground: const Color(0xFFEDEBE5),
          primary: const Color(0xFFEDEBE5),
          primaryForeground: const Color(0xFF161513),
          secondary: const Color(0xFF2D2B27),
          secondaryForeground: const Color(0xFFEDEBE5),
          muted: const Color(0xFF262420),
          mutedForeground: const Color(0xFFA6A298),
          accent: const Color(0xFF2D2B27),
          accentForeground: const Color(0xFFEDEBE5),
          destructive: const Color(0xFFC8432A),
          destructiveForeground: const Color(0xFFFFFFFF),
          border: const Color(0xFF2D2B27),
          input: const Color(0xFF34322D),
          ring: const Color(0xFF6B8BFF),
          selection: const Color(0xFF2B3560),
        );
}

/// Тема «Бумага» поверх компонентов shadcn.
class AppTheme {
  AppTheme._();

  static const _radius = BorderRadius.all(Radius.circular(10));

  static ShadThemeData get light => _build(
        Brightness.light,
        const VergeColorScheme.light(),
        VergePalette.light,
      );

  static ShadThemeData get dark => _build(
        Brightness.dark,
        const VergeColorScheme.dark(),
        VergePalette.dark,
      );

  static ShadThemeData _build(
    Brightness brightness,
    ShadColorScheme scheme,
    VergePalette palette,
  ) =>
      ShadThemeData(
        brightness: brightness,
        colorScheme: scheme,
        textTheme: _textTheme,
        radius: _radius,
        // Включённые свитчи и чекбоксы — кобальтом, как в макете: чернильный
        // primary на них читается как «выключено».
        switchTheme: ShadSwitchTheme(
          checkedTrackColor: palette.accent,
          uncheckedTrackColor: palette.idleTrack,
          thumbColor: const Color(0xFFFFFFFF),
        ),
        checkboxTheme: ShadCheckboxTheme(color: palette.accent),
      );

  /// Onest во всех стилях shadcn + emoji-фолбэк.
  ///
  /// Одной точки для фолбэка у ShadTextTheme нет: `family` задаёт основной
  /// шрифт, а fontFamilyFallback живёт только в отдельных TextStyle. Поэтому
  /// перечисляем стили руками — при обновлении shadcn_ui список стоит сверить
  /// с ShadTextTheme.
  static ShadTextTheme get _textTheme {
    final base = ShadTextTheme(family: kUiFontFamily);
    TextStyle f(TextStyle s) =>
        s.copyWith(fontFamilyFallback: kEmojiFontFallback);
    return ShadTextTheme.custom(
      h1Large: f(base.h1Large),
      h1: f(base.h1),
      h2: f(base.h2),
      h3: f(base.h3),
      h4: f(base.h4),
      p: f(base.p),
      blockquote: f(base.blockquote),
      table: f(base.table),
      list: f(base.list),
      lead: f(base.lead),
      large: f(base.large),
      small: f(base.small),
      muted: f(base.muted),
      family: base.family,
    );
  }
}
