import 'package:flutter/material.dart';

/// AppTheme 类包含了应用的所有自定义主题样式。
class AppTheme {
  static ThemeData get basicLight => ThemeData(
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(128, 109, 255, 1),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(248, 248, 255, 1),
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(248, 248, 255, 1),
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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

  static ThemeData get basicDark => ThemeData(
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(128, 109, 255, 1),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(128, 109, 255, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(31, 29, 44, 1),
        cardColor: const Color.fromRGBO(38, 40, 55, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(38, 40, 55, 1),
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(38, 40, 55, 1),
          selectedItemColor: Color.fromRGBO(128, 109, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white60,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(38, 40, 55, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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

  static ThemeData get ionicLightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(0, 122, 255, 1),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(0, 122, 255, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(248, 248, 255, 1),
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(248, 248, 255, 1),
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(10, 132, 255, 1),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(10, 132, 255, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(28, 28, 30, 1),
        cardColor: const Color.fromRGBO(44, 44, 46, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(44, 44, 46, 1),
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(44, 44, 46, 1),
          selectedItemColor: Color.fromRGBO(10, 132, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white60,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(44, 44, 46, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(25, 118, 210, 1),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(245, 245, 245, 1),
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(25, 118, 210, 1),
          unselectedItemColor: Color.fromRGBO(158, 158, 158, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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
        useMaterial3: true,
        fontFamily: 'SimSunExtG',
        // 设置全局字体为 SimSunExtG
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(33, 150, 243, 1),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontFamily: 'SimSunExtG',
              // 按钮字体改为 SimSunExtG
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        canvasColor: const Color.fromRGBO(18, 18, 18, 1),
        cardColor: const Color.fromRGBO(28, 28, 30, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          selectedItemColor: Color.fromRGBO(33, 150, 243, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            // 改为 SimSunExtG
            inherit: true,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white60,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'SimSunExtG',
            inherit: true,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(28, 28, 30, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
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
