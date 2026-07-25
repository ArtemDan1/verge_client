import 'package:flutter/material.dart';

/// Семантические цвета, не зависящие от ColorScheme.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF1FAA5B);

  static const Color pingGood = Color(0xFF1FAA5B); // < 150 мс
  static const Color pingMedium = Color(0xFFE08600); // < 400 мс
  static const Color pingBad = Color(0xFFD92D20); // >= 400 мс

  /// Цвет бейджа по задержке в мс.
  static Color pingColor(int ms) {
    if (ms < 150) return pingGood;
    if (ms < 400) return pingMedium;
    return pingBad;
  }
}
