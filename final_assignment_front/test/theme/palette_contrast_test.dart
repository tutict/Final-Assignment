import 'dart:math' as math;

import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double value) {
  final channel = value <= 1 ? value : value / 255;
  if (channel <= 0.04045) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  final r = _channel(color.r);
  final g = _channel(color.g);
  final b = _channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const palettes = [
    TrafficThemeColors.light,
    TrafficThemeColors.dark,
    BasicThemeColors.light,
    BasicThemeColors.dark,
    IonicThemeColors.light,
    IonicThemeColors.dark,
    MaterialThemeColors.light,
    MaterialThemeColors.dark,
  ];

  test('button text and input borders meet contrast floors', () {
    for (final palette in palettes) {
      expect(contrast(palette.button, palette.onButton), greaterThanOrEqualTo(4.5));
      expect(contrast(palette.inputBorder, palette.surface), greaterThanOrEqualTo(3));
      expect(contrast(palette.onSelected, palette.selected), greaterThanOrEqualTo(4.5));
    }
  });

  test('status colors stay independent of the pink brand', () {
    expect(AppColors.light.danger, const Color(0xFFB42318));
    expect(MaterialThemeColors.light.button, isNot(AppColors.light.danger));
    expect(contrast(AppColors.light.warning, const Color(0xFFFFF4D6)), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.dark.warning, const Color(0xFF2A1D08)), greaterThanOrEqualTo(4.5));
  });

  test('danger actions stay on the fixed red, including Material', () {
    expect(AppTheme.materialLightTheme.colorScheme.error, AppColors.light.danger);
    expect(AppTheme.materialDarkTheme.colorScheme.error, AppColors.dark.danger);
    expect(AppTheme.basicLight.colorScheme.error, AppColors.light.danger);
    expect(AppTheme.materialLightTheme.colorScheme.onError, AppColors.light.onDanger);
  });
}
