import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

/// Нейтральная (neutral) тема shadcn, без яркого акцентного цвета.
class AppTheme {
  AppTheme._();

  static ShadThemeData get light => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadNeutralColorScheme.light(),
        textTheme: _textTheme,
      );

  static ShadThemeData get dark => ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadNeutralColorScheme.dark(),
        textTheme: _textTheme,
      );

  /// Дефолтная тема shadcn, где каждому стилю дописан emoji-фолбэк.
  ///
  /// Одной точки для этого у ShadTextTheme нет: `family` задаёт основной
  /// шрифт, а fontFamilyFallback живёт только в отдельных TextStyle. Поэтому
  /// перечисляем стили руками — при обновлении shadcn_ui список стоит сверить
  /// с ShadTextTheme.
  static ShadTextTheme get _textTheme {
    final base = ShadTextTheme();
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
