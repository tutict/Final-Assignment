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
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontFamily: 'SimSunExtG',
      inherit: true,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'SimSunExtG',
      inherit: true,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontFamily: 'SimSunExtG',
      inherit: true,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontFamily: 'SimSunExtG',
      inherit: true,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'SimSunExtG',
      inherit: true,
    ),
  );

  /// 通用按钮主题
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
            fontWeight: FontWeight.w500,
            inherit: true,
          ),
        ),
      );

  /// 通用输入框装饰主题
  static InputDecorationTheme inputDecorationTheme(
      ColorScheme colorScheme, Color fillColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeStyles.inputBorderRadius),
          borderSide: const BorderSide(
            color: Colors.grey,
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
      );

  /// 基本亮色主题
  static ThemeData get basicLight => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BasicThemeColors.seedColor,
      brightness: Brightness.light,
    ),
    elevatedButtonTheme:
    elevatedButtonTheme(ColorScheme.fromSeed(seedColor: BasicThemeColors.seedColor)),
    canvasColor: BasicThemeColors.lightCanvasColor,
    cardColor: BasicThemeColors.lightCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: BasicThemeColors.lightCanvasColor,
      foregroundColor: Colors.black,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: BasicThemeColors.lightCardColor,
      selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: BasicThemeColors.seedColor),
      BasicThemeColors.lightCardColor,
    ),
  );

  /// 基本暗色主题
  static ThemeData get basicDark => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BasicThemeColors.seedColor,
      brightness: Brightness.dark,
    ),
    elevatedButtonTheme:
    elevatedButtonTheme(ColorScheme.fromSeed(seedColor: BasicThemeColors.seedColor)),
    canvasColor: BasicThemeColors.darkCanvasColor,
    cardColor: BasicThemeColors.darkCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: BasicThemeColors.darkCardColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: BasicThemeColors.darkCardColor,
      selectedItemColor: BasicThemeColors.seedColor,
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: BasicThemeColors.seedColor),
      BasicThemeColors.darkCardColor,
    ),
  );

  /// Ionic 亮色主题
  static ThemeData get ionicLightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: IonicThemeColors.lightSeedColor,
      brightness: Brightness.light,
    ),
    elevatedButtonTheme: elevatedButtonTheme(
        ColorScheme.fromSeed(seedColor: IonicThemeColors.lightSeedColor)),
    canvasColor: IonicThemeColors.lightCanvasColor,
    cardColor: IonicThemeColors.lightCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: IonicThemeColors.lightCanvasColor,
      foregroundColor: Colors.black,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: IonicThemeColors.lightCardColor,
      selectedItemColor: IonicThemeColors.lightSeedColor,
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: IonicThemeColors.lightSeedColor),
      IonicThemeColors.lightCardColor,
    ),
  );

  /// Ionic 暗色主题
  static ThemeData get ionicDarkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: IonicThemeColors.darkSeedColor,
      brightness: Brightness.dark,
    ),
    elevatedButtonTheme: elevatedButtonTheme(
        ColorScheme.fromSeed(seedColor: IonicThemeColors.darkSeedColor)),
    canvasColor: IonicThemeColors.darkCanvasColor,
    cardColor: IonicThemeColors.darkCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: IonicThemeColors.darkCardColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: IonicThemeColors.darkCardColor,
      selectedItemColor: IonicThemeColors.darkSeedColor,
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: IonicThemeColors.darkSeedColor),
      IonicThemeColors.darkCardColor,
    ),
  );

  /// Material 亮色主题
  static ThemeData get materialLightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MaterialThemeColors.lightSeedColor,
      brightness: Brightness.light,
    ),
    elevatedButtonTheme: elevatedButtonTheme(
        ColorScheme.fromSeed(seedColor: MaterialThemeColors.lightSeedColor)),
    canvasColor: MaterialThemeColors.lightCanvasColor,
    cardColor: MaterialThemeColors.lightCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: MaterialThemeColors.lightCardColor,
      foregroundColor: Colors.black,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MaterialThemeColors.lightCardColor,
      selectedItemColor: MaterialThemeColors.lightSeedColor,
      unselectedItemColor: Color.fromRGBO(158, 158, 158, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: MaterialThemeColors.lightSeedColor),
      MaterialThemeColors.lightCardColor,
    ),
  );

  /// Material 暗色主题
  static ThemeData get materialDarkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SimSunExtG',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MaterialThemeColors.darkSeedColor,
      brightness: Brightness.dark,
    ),
    elevatedButtonTheme: elevatedButtonTheme(
        ColorScheme.fromSeed(seedColor: MaterialThemeColors.darkSeedColor)),
    canvasColor: MaterialThemeColors.darkCanvasColor,
    cardColor: MaterialThemeColors.darkCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: MaterialThemeColors.darkCardColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MaterialThemeColors.darkCardColor,
      selectedItemColor: MaterialThemeColors.darkSeedColor,
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
      elevation: 8,
    ),
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme(
      ColorScheme.fromSeed(seedColor: MaterialThemeColors.darkSeedColor),
      MaterialThemeColors.darkCardColor,
    ),
  );
}