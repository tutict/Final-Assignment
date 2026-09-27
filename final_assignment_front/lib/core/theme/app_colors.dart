import 'package:flutter/material.dart';

/// Semantic colors that [ColorScheme] does not provide (e.g. success/warning).
/// Registered as a [ThemeExtension] on every theme in AppTheme so any
/// screen can read it via Theme.of(context).extension<AppColors>().
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successBackground,
    required this.warning,
    required this.onWarning,
    required this.warningBackground,
    required this.danger,
    required this.onDanger,
    required this.dangerBackground,
    required this.info,
    required this.onInfo,
    required this.infoBackground,
  });

  final Color success;
  final Color onSuccess;
  final Color successBackground;
  final Color warning;
  final Color onWarning;
  final Color warningBackground;
  final Color danger;
  final Color onDanger;
  final Color dangerBackground;
  final Color info;
  final Color onInfo;
  final Color infoBackground;

  static const light = AppColors(
    success: Color(0xFF0F6B38),
    onSuccess: Color(0xFFFFFFFF),
    successBackground: Color(0xFFE5F6EC),
    warning: Color(0xFF7A3E00),
    onWarning: Color(0xFFFFFFFF),
    warningBackground: Color(0xFFFFF4D6),
    danger: Color(0xFFB42318),
    onDanger: Color(0xFFFFFFFF),
    dangerBackground: Color(0xFFFDECEC),
    info: Color(0xFF1F2937),
    onInfo: Color(0xFF1F2937),
    infoBackground: Color(0xFFEEF2F6),
  );

  static const dark = AppColors(
    success: Color(0xFF6EE7A8),
    onSuccess: Color(0xFF042014),
    successBackground: Color(0xFF0E2A1C),
    warning: Color(0xFFF5C16C),
    onWarning: Color(0xFF2A1D08),
    warningBackground: Color(0xFF2A1D08),
    danger: Color(0xFFFCA5A5),
    onDanger: Color(0xFF3A1212),
    dangerBackground: Color(0xFF3A1212),
    info: Color(0xFFE5E7EB),
    onInfo: Color(0xFFE5E7EB),
    infoBackground: Color(0xFF1F2937),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successBackground,
    Color? warning,
    Color? onWarning,
    Color? warningBackground,
    Color? danger,
    Color? onDanger,
    Color? dangerBackground,
    Color? info,
    Color? onInfo,
    Color? infoBackground,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successBackground: successBackground ?? this.successBackground,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningBackground: warningBackground ?? this.warningBackground,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerBackground: dangerBackground ?? this.dangerBackground,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoBackground: infoBackground ?? this.infoBackground,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successBackground: Color.lerp(successBackground, other.successBackground, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningBackground: Color.lerp(warningBackground, other.warningBackground, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerBackground: Color.lerp(dangerBackground, other.dangerBackground, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
    );
  }
}


class ChartColors {
  const ChartColors._();

  static const List<Color> category = [
    Color(0xFF1E3A8A),
    Color(0xFF0F766E),
    Color(0xFFB45309),
    Color(0xFF6D28D9),
    Color(0xFF0369A1),
    Color(0xFF3F6212),
  ];

  static Color at(int index) => category[index % category.length];
}
