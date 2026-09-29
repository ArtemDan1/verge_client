import 'package:flutter/material.dart';

/// Семантические цвета, не зависящие от ColorScheme.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF1FAA5B);

  // Заливки чипа пинга под белым текстом: темнее «сигнальных» оттенков
  // палитры, чтобы подпись проходила по контрасту в обеих темах.
  static const Color pingGood = Color(0xFF177A42); // < 150 мс
  static const Color pingMedium = Color(0xFFB45309); // < 400 мс
  static const Color pingBad = Color(0xFFB42318); // >= 400 мс

  /// Цвет бейджа по задержке в мс.
  static Color pingColor(int ms) {
    if (ms < 150) return pingGood;
    if (ms < 400) return pingMedium;
    return pingBad;
  }
}
