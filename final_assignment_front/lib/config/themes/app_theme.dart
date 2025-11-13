import 'package:flutter/material.dart';

/// 主题样式常量
class ThemeStyles {
  static const double buttonBorderRadius = 16.0;
  static const double buttonElevation = 2.0;
  static const double defaultFontSize = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double inputBorderWidth = 1.0;
  static const double inputFocusedBorderWidth = 2.0;
}

/// 基本主题颜色
class BasicThemeColors {
  static const seedColor = Color.fromRGBO(128, 109, 255, 1);
  static const lightCanvasColor = Color.fromRGBO(248, 248, 255, 1);
  static const darkCanvasColor = Color.fromRGBO(31, 29, 44, 1);
  static const lightCardColor = Color.fromRGBO(255, 255, 255, 1);
  static const darkCardColor = Color.fromRGBO(38, 40, 55, 1);
}

/// Ionic 主题颜色
class IonicThemeColors {
  static const lightSeedColor = Color.fromRGBO(0, 122, 255, 1);
  static const darkSeedColor = Color.fromRGBO(10, 132, 255, 1);
  static const lightCanvasColor = Color.fromRGBO(248, 248, 255, 1);
  static const darkCanvasColor = Color.fromRGBO(28, 28, 30, 1);
  static const lightCardColor = Color.fromRGBO(255, 255, 255, 1);
  static const darkCardColor = Color.fromRGBO(44, 44, 46, 1);
}

/// Material 主题颜色
class MaterialThemeColors {
  static const lightSeedColor = Color.fromRGBO(25, 118, 210, 1);
  static const darkSeedColor = Color.fromRGBO(33, 150, 243, 1);
  static const lightCanvasColor = Color.fromRGBO(245, 245, 245, 1);
  static const darkCanvasColor = Color.fromRGBO(18, 18, 18, 1);
  static const lightCardColor = Color.fromRGBO(255, 255, 255, 1);
  static const darkCardColor = Color.fromRGBO(28, 28, 30, 1);
}

/// AppTheme 类包含了应用的所有自定义主题样式。
class AppTheme {
  /// 通用文本主题，颜色由 colorScheme 决定
  static TextTheme textTheme(Color baseColor) => TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          fontFamily: 'SimSunExtG',
          color: baseColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'SimSunExtG',
          color: baseColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontFamily: 'SimSunExtG',
          color: baseColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontFamily: 'SimSunExtG',
          color: baseColor.withOpacity(0.9),
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'SimSunExtG',
          color: baseColor,
        ),
      );

  /// 基础按钮主题
  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: ThemeStyles.buttonElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeStyles.buttonBorderRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SimSunExtG',
            fontSize: ThemeStyles.defaultFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  /// 描边按钮主题
  static OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeStyles.buttonBorderRadius),
          ),
          textStyle: TextStyle(
            fontFamily: 'SimSunExtG',
            fontSize: ThemeStyles.defaultFontSize,
            color: colorScheme.primary,
          ),
        ),
      );

  /// 通用输入框装饰主题
  static InputDecorationTheme inputDecorationTheme(
    ColorScheme colorScheme,
    Color fillColor,
  ) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: ThemeStyles.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: ThemeStyles.inputFocusedBorderWidth,
          ),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontFamily: 'SimSunExtG',
        ),
      );

  /// 构建统一的基础主题，供不同配色调用
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
    required Color canvasColor,
    required Color cardColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final bool isLight = brightness == Brightness.light;
    final Color baseTextColor =
        isLight ? Colors.black87 : Colors.white.withOpacity(0.95);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SimSunExtG',
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvasColor,
      canvasColor: canvasColor,
      cardColor: cardColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: textTheme(baseTextColor),
      elevatedButtonTheme: elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: outlinedButtonTheme(colorScheme),
      inputDecorationTheme: inputDecorationTheme(
        colorScheme,
        isLight ? cardColor : cardColor.withOpacity(0.9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvasColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: baseTextColor,
        titleTextStyle: textTheme(baseTextColor).titleLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        elevation: 6,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isLight ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          fontFamily: 'SimSunExtG',
          color: colorScheme.onPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.4),
        thickness: 0.8,
        space: 32,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme:
            IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme(baseTextColor).labelLarge,
        unselectedLabelTextStyle:
            textTheme(baseTextColor).labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
      ),
    );
  }

  /// 基本亮色主题
  static ThemeData get basicLight => _buildTheme(
        brightness: Brightness.light,
        seedColor: BasicThemeColors.seedColor,
        canvasColor: BasicThemeColors.lightCanvasColor,
        cardColor: BasicThemeColors.lightCardColor,
      );

  /// 基本暗色主题
  static ThemeData get basicDark => _buildTheme(
        brightness: Brightness.dark,
        seedColor: BasicThemeColors.seedColor,
        canvasColor: BasicThemeColors.darkCanvasColor,
        cardColor: BasicThemeColors.darkCardColor,
      );

  /// Ionic 亮色主题
  static ThemeData get ionicLightTheme => _buildTheme(
        brightness: Brightness.light,
        seedColor: IonicThemeColors.lightSeedColor,
        canvasColor: IonicThemeColors.lightCanvasColor,
        cardColor: IonicThemeColors.lightCardColor,
      );

  /// Ionic 暗色主题
  static ThemeData get ionicDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        seedColor: IonicThemeColors.darkSeedColor,
        canvasColor: IonicThemeColors.darkCanvasColor,
        cardColor: IonicThemeColors.darkCardColor,
      );

  /// Material 亮色主题
  static ThemeData get materialLightTheme => _buildTheme(
        brightness: Brightness.light,
        seedColor: MaterialThemeColors.lightSeedColor,
        canvasColor: MaterialThemeColors.lightCanvasColor,
        cardColor: MaterialThemeColors.lightCardColor,
      );

  /// Material 暗色主题
  static ThemeData get materialDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        seedColor: MaterialThemeColors.darkSeedColor,
        canvasColor: MaterialThemeColors.darkCanvasColor,
        cardColor: MaterialThemeColors.darkCardColor,
      );
}
