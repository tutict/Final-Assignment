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
        // Ionic primary blue color
        primaryColorLight: const Color.fromRGBO(102, 169, 255, 1),
        primaryColorDark: const Color.fromRGBO(0, 95, 204, 1),
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(0, 122, 255, 1),
          textStyle:
              const TextStyle(color: Colors.white).useSystemChineseFont(),
        ).merge(
          ButtonStyle(elevation: WidgetStateProperty.all(0)),
        )),
        canvasColor: const Color.fromRGBO(242, 242, 247, 1),
        // Ionic canvas color
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        // Ionic card color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)
              .useSystemChineseFont(),
          titleLarge: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)
              .useSystemChineseFont(),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.black)
              .useSystemChineseFont(),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.black)
              .useSystemChineseFont(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(0, 122, 255, 1),
              width: 2,
            ),
          ),
        ),
      );

  static ThemeData get ionicDarkTheme => ThemeData(
        fontFamily: 'Helvetica',
        primaryColor: const Color.fromRGBO(0, 122, 255, 1),
        // Ionic primary blue color
        primaryColorLight: const Color.fromRGBO(102, 169, 255, 1),
        primaryColorDark: const Color.fromRGBO(0, 95, 204, 1),
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(0, 122, 255, 1),
          textStyle:
              const TextStyle(color: Colors.white).useSystemChineseFont(),
        ).merge(
          ButtonStyle(elevation: WidgetStateProperty.all(0)),
        )),
        canvasColor: const Color.fromRGBO(18, 18, 18, 1),
        // Dark canvas color
        cardColor: const Color.fromRGBO(28, 28, 30, 1),
        // Dark card color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          selectedItemColor: Color.fromRGBO(0, 122, 255, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
              .useSystemChineseFont(),
          titleLarge: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
              .useSystemChineseFont(),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.white)
              .useSystemChineseFont(),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.white)
              .useSystemChineseFont(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(28, 28, 30, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(0, 122, 255, 1),
              width: 2,
            ),
          ),
        ),
      );

  static ThemeData get materialLightTheme => ThemeData(
        fontFamily: 'Helvetica',
        primaryColor: const Color.fromRGBO(33, 150, 243, 1),
        // Material primary blue color
        primaryColorLight: const Color.fromRGBO(100, 181, 246, 1),
        primaryColorDark: const Color.fromRGBO(25, 118, 210, 1),
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
            textStyle:
                const TextStyle(color: Colors.white).useSystemChineseFont(),
          ).merge(
            ButtonStyle(elevation: WidgetStateProperty.all(0)),
          ),
        ),
        canvasColor: const Color.fromRGBO(250, 250, 250, 1),
        // Light canvas color
        cardColor: const Color.fromRGBO(255, 255, 255, 1),
        // Light card color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          selectedItemColor: Color.fromRGBO(33, 150, 243, 1),
          unselectedItemColor: Color.fromRGBO(158, 158, 158, 1),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)
              .useSystemChineseFont(),
          titleLarge: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)
              .useSystemChineseFont(),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.black)
              .useSystemChineseFont(),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.black)
              .useSystemChineseFont(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(33, 150, 243, 1),
              width: 2,
            ),
          ),
        ),
      );

  static ThemeData get materialDarkTheme => ThemeData(
        fontFamily: 'Helvetica',
        primaryColor: const Color.fromRGBO(33, 150, 243, 1),
        // Material primary blue color
        primaryColorLight: const Color.fromRGBO(100, 181, 246, 1),
        primaryColorDark: const Color.fromRGBO(25, 118, 210, 1),
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
            textStyle:
                const TextStyle(color: Colors.white).useSystemChineseFont(),
          ).merge(
            ButtonStyle(elevation: WidgetStateProperty.all(0)),
          ),
        ),
        canvasColor: const Color.fromRGBO(18, 18, 18, 1),
        // Dark canvas color
        cardColor: const Color.fromRGBO(28, 28, 30, 1),
        // Dark card color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(28, 28, 30, 1),
          selectedItemColor: Color.fromRGBO(33, 150, 243, 1),
          unselectedItemColor: Color.fromRGBO(142, 142, 147, 1),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
              .useSystemChineseFont(),
          titleLarge: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
              .useSystemChineseFont(),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.white)
              .useSystemChineseFont(),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.white)
              .useSystemChineseFont(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(28, 28, 30, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(33, 150, 243, 1),
              width: 2,
            ),
          ),
        ),
      );
}
