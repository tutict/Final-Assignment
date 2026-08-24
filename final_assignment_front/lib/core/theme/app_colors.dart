import 'package:flutter/material.dart';

/// Semantic colors that [ColorScheme] does not provide (e.g. success).
/// Registered as a [ThemeExtension] on every theme in `AppTheme` so any
/// screen can read it via `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
  });

  final Color success;
  final Color onSuccess;

  static const light = AppColors(
    success: Color(0xFF1FA65A),
    onSuccess: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    success: Color(0xFF4DD08A),
    onSuccess: Color(0xFF06281A),
  );

  @override
  AppColors copyWith({Color? success, Color? onSuccess}) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}
