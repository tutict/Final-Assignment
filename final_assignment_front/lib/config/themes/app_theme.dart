import 'package:flutter/material.dart';

class ThemeStyles {
  static const double buttonBorderRadius = 18.0;
  static const double cardBorderRadius = 26.0;
  static const double inputBorderRadius = 18.0;
  static const double chipBorderRadius = 20.0;
  static const double buttonElevation = 0.0;
  static const double inputBorderWidth = 1.2;
  static const double inputFocusedBorderWidth = 1.8;
  static const double defaultFontSize = 16.0;
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
}

class ThemePalette {
  const ThemePalette({
    required this.seed,
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceTint,
    required this.outline,
    required this.shadow,
  });

  final Color seed;
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceTint;
  final Color outline;
  final Color shadow;
}

class BasicThemeColors {
  static const light = ThemePalette(
    seed: Color(0xFF1565C0),
    scaffold: Color(0xFFF3F7FC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE8F0FA),
    surfaceTint: Color(0xFF90CAF9),
    outline: Color(0xFFB3C3D9),
    shadow: Color(0x1A0D233F),
  );

  static const dark = ThemePalette(
    seed: Color(0xFF6CB6FF),
    scaffold: Color(0xFF0B1421),
    surface: Color(0xFF132033),
    surfaceAlt: Color(0xFF1A2A40),
    surfaceTint: Color(0xFF1F3C64),
    outline: Color(0xFF3D5370),
    shadow: Color(0x66000000),
  );
}

class IonicThemeColors {
  static const light = ThemePalette(
    seed: Color(0xFF00838F),
    scaffold: Color(0xFFF2FAFA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFDFF4F5),
    surfaceTint: Color(0xFF8FE7EB),
    outline: Color(0xFF9CC8CC),
    shadow: Color(0x160B3A3D),
  );

  static const dark = ThemePalette(
    seed: Color(0xFF4DD0E1),
    scaffold: Color(0xFF09181B),
    surface: Color(0xFF102428),
    surfaceAlt: Color(0xFF153036),
    surfaceTint: Color(0xFF18444C),
    outline: Color(0xFF3A646A),
    shadow: Color(0x70000000),
  );
}

class MaterialThemeColors {
  static const light = ThemePalette(
    seed: Color(0xFFAD1457),
    scaffold: Color(0xFFFCF5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF7E3EB),
    surfaceTint: Color(0xFFF3B7CD),
    outline: Color(0xFFD5B5C3),
    shadow: Color(0x190E1020),
  );

  static const dark = ThemePalette(
    seed: Color(0xFFFF7EB6),
    scaffold: Color(0xFF171019),
    surface: Color(0xFF241722),
    surfaceAlt: Color(0xFF311E2C),
    surfaceTint: Color(0xFF492739),
    outline: Color(0xFF705160),
    shadow: Color(0x78000000),
  );
}

class AppTheme {
  static const List<String> chineseFontFallback = [
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
    'SimHei',
    'SimSun',
  ];

  static TextTheme _textTheme(Color textColor, Color mutedTextColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -1.2,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.14,
        letterSpacing: -0.4,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.22,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.24,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.26,
        letterSpacing: -0.2,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: mutedTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: mutedTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: mutedTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: mutedTextColor,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        elevation: ThemeStyles.buttonElevation,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(
          fontSize: ThemeStyles.defaultFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.buttonBorderRadius),
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: ThemeStyles.defaultFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: ThemeStyles.defaultFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required ColorScheme colorScheme,
    required Color fillColor,
  }) {
    OutlineInputBorder buildBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeStyles.inputBorderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: buildBorder(
        colorScheme.outlineVariant,
        ThemeStyles.inputBorderWidth,
      ),
      enabledBorder: buildBorder(
        colorScheme.outlineVariant,
        ThemeStyles.inputBorderWidth,
      ),
      focusedBorder: buildBorder(
        colorScheme.primary,
        ThemeStyles.inputFocusedBorderWidth,
      ),
      errorBorder: buildBorder(
        colorScheme.error,
        ThemeStyles.inputFocusedBorderWidth,
      ),
      focusedErrorBorder: buildBorder(
        colorScheme.error,
        ThemeStyles.inputFocusedBorderWidth,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ThemePalette palette,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
      surface: palette.surface,
    ).copyWith(
      surface: palette.surface,
      surfaceContainer: palette.surfaceAlt.withValues(alpha: 0.72),
      surfaceContainerHigh: palette.surfaceAlt.withValues(alpha: 0.86),
      surfaceContainerHighest: palette.surfaceAlt,
      outline: palette.outline,
      outlineVariant: palette.outline.withValues(alpha: 0.72),
      shadow: palette.shadow,
      scrim: Colors.black.withValues(alpha: brightness == Brightness.light ? 0.2 : 0.45),
    );

    final isLight = brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF102033) : const Color(0xFFF3F7FF);
    final mutedTextColor = isLight
        ? const Color(0xFF516174)
        : const Color(0xFFC0CCDC);
    final textTheme = _textTheme(textColor, mutedTextColor);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamilyFallback: chineseFontFallback,
      scaffoldBackgroundColor: palette.scaffold,
      canvasColor: palette.scaffold,
      cardColor: palette.surface,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
      shadowColor: palette.shadow,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      textButtonTheme: _textButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme: colorScheme,
        fillColor: isLight
            ? palette.surface
            : palette.surfaceAlt.withValues(alpha: 0.88),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.scaffold.withValues(alpha: isLight ? 0.92 : 0.94),
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.78),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.78),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        groupAlignment: -0.7,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: palette.surfaceTint.withValues(alpha: isLight ? 0.08 : 0.16),
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.cardBorderRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: isLight ? 0.32 : 0.5),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onPrimaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: textTheme.labelMedium,
        brightness: brightness,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.chipBorderRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: palette.surfaceTint.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textColor),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: palette.surfaceTint.withValues(alpha: 0.08),
        modalBackgroundColor: palette.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF102033) : const Color(0xFFE6EEF9),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : const Color(0xFF0B1421),
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        thickness: 0.9,
        space: 28,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: textColor,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.35);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: palette.surfaceTint.withValues(alpha: 0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: textColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFF102033) : const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isLight ? Colors.white : const Color(0xFF102033),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get basicLight => _buildTheme(
        brightness: Brightness.light,
        palette: BasicThemeColors.light,
      );

  static ThemeData get basicDark => _buildTheme(
        brightness: Brightness.dark,
        palette: BasicThemeColors.dark,
      );

  static ThemeData get ionicLightTheme => _buildTheme(
        brightness: Brightness.light,
        palette: IonicThemeColors.light,
      );

  static ThemeData get ionicDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        palette: IonicThemeColors.dark,
      );

  static ThemeData get materialLightTheme => _buildTheme(
        brightness: Brightness.light,
        palette: MaterialThemeColors.light,
      );

  static ThemeData get materialDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        palette: MaterialThemeColors.dark,
      );
}
