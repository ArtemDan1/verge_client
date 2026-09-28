import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/theme/app_theme.dart';

void main() {
  test('light theme is light and uses Verge color scheme', () {
    final t = AppTheme.light;
    expect(t.brightness, Brightness.light);
    expect(t.colorScheme, isA<VergeColorScheme>());
  });

  test('dark theme is dark and uses Verge color scheme', () {
    final t = AppTheme.dark;
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme, isA<VergeColorScheme>());
  });
}
