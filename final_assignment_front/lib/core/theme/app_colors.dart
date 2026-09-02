import 'package:flutter/material.dart';

/// Semantic colors that [ColorScheme] does not provide (e.g. success/warning).
/// Registered as a [ThemeExtension] on every theme in `AppTheme` so any
/// screen can read it via `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;

  static const light = AppColors(
    success: Color(0xFF1FA65A),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    info: Color(0xFF3B82F6),
    onInfo: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    success: Color(0xFF4DD08A),
    onSuccess: Color(0xFF06281A),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF2D1A04),
    danger: Color(0xFFF87171),
    onDanger: Color(0xFF2B0707),
    info: Color(0xFF60A5FA),
    onInfo: Color(0xFF061732),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? info,
    Color? onInfo,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
