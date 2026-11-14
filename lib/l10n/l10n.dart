import 'dart:ui';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Язык интерфейса, выбранный пользователем, или null — как в системе.
///
/// Строки берутся через глобальный [l10n], а не `AppLocalizations.of(context)`:
/// их показывает и код без контекста (контроллер, сервисы — тосты, логи,
/// ошибки). При смене языка приложение перестраивает всё дерево целиком
/// (см. SingboxApp), так что виджеты подхватывают новый язык и без подписки
/// на Localizations.
AppLocalizations _current = lookupAppLocalizations(const Locale('en'));
Locale _locale = const Locale('en');

/// Строки текущего языка интерфейса.
AppLocalizations get l10n => _current;

/// Текущий язык интерфейса.
Locale get appLocale => _locale;

/// Языки в селекторе настроек: код → самоназвание. Порядок — порядок показа.
const appLanguages = <String, String>{
  'en': 'English',
  'ru': 'Русский',
  'zh': '简体中文',
  'fa': 'فارسی',
  'ar': 'العربية',
  'tr': 'Türkçe',
  'es': 'Español',
  'pt': 'Português',
  'de': 'Deutsch',
  'fr': 'Français',
};

/// Язык для кода из настроек: [code] null — системный, а если система на
/// языке, которого нет, — английский.
Locale resolveAppLocale(String? code, [List<Locale>? system]) {
  if (code != null && appLanguages.containsKey(code)) return Locale(code);
  for (final l in system ?? PlatformDispatcher.instance.locales) {
    if (appLanguages.containsKey(l.languageCode)) return Locale(l.languageCode);
  }
  return const Locale('en');
}

/// Переключить язык строк [l10n]. Возвращает true, если язык сменился.
bool setAppLocale(Locale locale) {
  if (locale == _locale) return false;
  _locale = locale;
  _current = lookupAppLocalizations(locale);
  return true;
}
