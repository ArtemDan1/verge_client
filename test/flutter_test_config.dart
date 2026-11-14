import 'dart:async';
import 'dart:ui';

import 'package:singbox_client/l10n/l10n.dart';

/// Тесты писались под русский интерфейс и сверяют строки на нём —
/// фиксируем язык, чтобы результат не зависел от локали машины.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setAppLocale(const Locale('ru'));
  await testMain();
}
