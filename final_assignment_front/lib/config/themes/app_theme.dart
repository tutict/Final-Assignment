import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// AppTheme 类包含了应用的所有自定义主题样式。
class AppTheme {
  /// 返回一个基本的浅色主题样式。
  static ThemeData get basicLight => ThemeData(
        // 设置字体家族为 Poppins。
        fontFamily: Font.poppins,
        // 设置暗色主题的主要颜色。
        primaryColorDark: const Color.fromRGBO(111, 88, 255, 1),
        // 设置主题的主要颜色。
        primaryColor: const Color.fromRGBO(128, 109, 255, 1),
        // 设置浅色主题的主要颜色。
        primaryColorLight: const Color.fromRGBO(159, 84, 252, 1),
        // 设置主题的亮度为亮色。
        brightness: Brightness.light,
        // 设置主题的主色为深紫色。
        primarySwatch: Colors.deepPurple,
        // 设置凸起按钮的主题样式，包括背景颜色和取消阴影效果。
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
        ).merge(
          ButtonStyle(elevation: WidgetStateProperty.all(0)),
        )),
        // 设置画布颜色。
        canvasColor: const Color.fromRGBO(31, 29, 44, 1),
        // 设置卡片颜色。
        cardColor: const Color.fromRGBO(38, 40, 55, 1),
      );

  /// 返回一个基本的深色主题样式。
  static ThemeData get basicDark => ThemeData(
        fontFamily: Font.poppins,
        primaryColorDark: const Color.fromRGBO(111, 88, 255, 1),
        primaryColor: const Color.fromRGBO(128, 109, 255, 1),
        primaryColorLight: const Color.fromRGBO(159, 84, 252, 1),
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
        ).merge(
          ButtonStyle(elevation: WidgetStateProperty.all(0)),
        )),
        canvasColor: const Color.fromRGBO(31, 29, 44, 1),
        cardColor: const Color.fromRGBO(38, 40, 55, 1),
      );

  static ThemeData get ionicLightTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(0, 122, 255, 1),
    primaryColorLight: const Color.fromRGBO(153, 204, 255, 1),
    primaryColorDark: const Color.fromRGBO(0, 95, 204, 1),
    brightness: Brightness.light,
    primarySwatch: Colors.lightBlue,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(0, 122, 255, 1),
        textStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(248, 248, 255, 1),
    cardColor: const Color.fromRGBO(255, 255, 255, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(248, 248, 255, 1),
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(0, 122, 255, 1),
          width: 2,
        ),
      ),
    ),
  );

  static ThemeData get ionicDarkTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(10, 132, 255, 1),
    primaryColorLight: const Color.fromRGBO(64, 156, 255, 1),
    primaryColorDark: const Color.fromRGBO(0, 95, 204, 1),
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(10, 132, 255, 1),
        textStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(28, 28, 30, 1),
    cardColor: const Color.fromRGBO(44, 44, 46, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(44, 44, 46, 1),
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(44, 44, 46, 1),
      selectedItemColor: Color.fromRGBO(10, 132, 255, 1),
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white60,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(44, 44, 46, 1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(10, 132, 255, 1),
          width: 2,
        ),
      ),
    ),
  );

  static ThemeData get materialLightTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(25, 118, 210, 1),
    primaryColorLight: const Color.fromRGBO(144, 202, 249, 1),
    primaryColorDark: const Color.fromRGBO(21, 101, 192, 1),
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
        textStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(245, 245, 245, 1),
    cardColor: const Color.fromRGBO(255, 255, 255, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      selectedItemColor: Color.fromRGBO(25, 118, 210, 1),
      unselectedItemColor: Color.fromRGBO(158, 158, 158, 1),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(25, 118, 210, 1),
          width: 2,
        ),
      ),
    ),
  );

  static ThemeData get materialDarkTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(33, 150, 243, 1),
    primaryColorLight: const Color.fromRGBO(100, 181, 246, 1),
    primaryColorDark: const Color.fromRGBO(25, 118, 210, 1),
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
        textStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(18, 18, 18, 1),
    cardColor: const Color.fromRGBO(28, 28, 30, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(28, 28, 30, 1),
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(28, 28, 30, 1),
      selectedItemColor: Color.fromRGBO(33, 150, 243, 1),
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white60,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(28, 28, 30, 1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(33, 150, 243, 1),
          width: 2,
        ),
      ),
    ),
  );
}