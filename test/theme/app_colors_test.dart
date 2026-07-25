import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/theme/app_colors.dart';

void main() {
  test('seed is green', () {
    expect(AppColors.seed, const Color(0xFF1FAA5B));
  });

  test('pingColor thresholds', () {
    expect(AppColors.pingColor(100), AppColors.pingGood);
    expect(AppColors.pingColor(150), AppColors.pingMedium);
    expect(AppColors.pingColor(399), AppColors.pingMedium);
    expect(AppColors.pingColor(400), AppColors.pingBad);
  });
}
