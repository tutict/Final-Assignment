import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// AppTheme 类包含了应用的所有自定义主题样式。
class AppTheme {
  static ThemeData get basicLight => ThemeData(
        useMaterial3: true,
        fontFamily: Font.poppins,
        brightness: Brightness.light,
        // 根据种子颜色自动生成完整的 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(128, 109, 255, 1),
          brightness: Brightness.light,
        ),
        // 自定义 ElevatedButton 样式，取消阴影
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
            elevation: 0,
          ),
        ),
        // 设置画布与卡片颜色
        canvasColor: const Color.fromRGBO(248, 248, 255, 1),
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        // 自定义 AppBar 样式
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(248, 248, 255, 1),
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        // 自定义底部导航栏样式
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        // 自定义文本主题
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
        // 自定义输入框装饰主题
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

  /// 返回一个基本的深色主题样式，使用 Material 3 的动态色彩
  static ThemeData get basicDark => ThemeData(
        useMaterial3: true,
        fontFamily: Font.poppins,
        brightness: Brightness.dark,
        // 根据相同种子颜色生成深色版 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(128, 109, 255, 1),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
            elevation: 0,
          ),
        ),
        // 保持之前的深色调
        canvasColor: const Color.fromRGBO(31, 29, 44, 1),
        // 旧的深色背景
        cardColor: const Color.fromRGBO(38, 40, 55, 1),
        // 旧的卡片背景色
        // 自定义 AppBar 样式
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(38, 40, 55, 1),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        // 自定义底部导航栏样式
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(38, 40, 55, 1),
          selectedItemColor: Color.fromRGBO(128, 109, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        // 自定义文本主题
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
        // 自定义输入框装饰主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(38, 40, 55, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromRGBO(128, 109, 255, 1),
              width: 2,
            ),
          ),
        ),
      );

  /// 返回一个基于 Ionic 风格的浅色主题样式（动态色彩）。
  static ThemeData get ionicLightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        brightness: Brightness.light,
        // 根据种子颜色自动生成完整的 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(0, 122, 255, 1),
          brightness: Brightness.light,
        ),
        // 自定义 ElevatedButton 样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(0, 122, 255, 1),
            textStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // 设置画布与卡片颜色（可根据需要调整）
        canvasColor: const Color.fromRGBO(248, 248, 255, 1),
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        // 自定义 AppBar 样式
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(248, 248, 255, 1),
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        // 自定义底部导航栏样式
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        // 自定义文本主题
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
        // 自定义输入框装饰主题
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

  /// 返回一个基于 Ionic 风格的深色主题样式（动态色彩）。
  static ThemeData get ionicDarkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        brightness: Brightness.dark,
        // 根据种子颜色自动生成完整的深色 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(10, 132, 255, 1),
          brightness: Brightness.dark,
        ),
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

  /// 返回一个基于Material风格的浅色主题样式，使用 Material 3 的动态色彩特性。
  static ThemeData get materialLightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        brightness: Brightness.light,
        // 根据种子颜色自动生成完整的 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(25, 118, 210, 1),
          brightness: Brightness.light,
        ),
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

  /// 返回一个基于Material风格的深色主题样式，使用 Material 3 的动态色彩特性。
  static ThemeData get materialDarkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        brightness: Brightness.dark,
        // 根据种子颜色自动生成完整的深色 ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(33, 150, 243, 1),
          brightness: Brightness.dark,
        ),
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
