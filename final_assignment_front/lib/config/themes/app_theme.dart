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
    // 设置主色为深紫色。
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

  /// 返回一个基于Ionic风格的浅色主题样式。
  static ThemeData get ionicLightTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(0, 122, 255, 1), // 设置主要颜色。
    primaryColorLight: const Color.fromRGBO(153, 204, 255, 1), // 设置浅色主要颜色。
    primaryColorDark: const Color.fromRGBO(0, 95, 204, 1), // 设置深色主要颜色。
    brightness: Brightness.light, // 设置亮度为亮色。
    primarySwatch: Colors.lightBlue, // 设置主色的色标。
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(0, 122, 255, 1), // 设置凸起按钮的背景颜色。
        textStyle: const TextStyle(color: Colors.white), // 设置按钮文字的样式。
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 设置边框圆角度。
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(248, 248, 255, 1), // 设置画布颜色。
    cardColor: const Color.fromRGBO(255, 255, 255, 1), // 设置卡片颜色。
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(248, 248, 255, 1), // 设置 AppBar 背景颜色。
      foregroundColor: Colors.black, // 设置 AppBar 文字颜色。
      elevation: 1, // 设置阴影度。
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1), // 设置底部导航栏背景颜色。
      selectedItemColor: Color.fromRGBO(0, 122, 255, 1), // 设置选中项的颜色。
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1), // 设置未选中项的颜色。
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, // 设置展示大尺寸文字的字号。
        fontWeight: FontWeight.bold, // 设置字体稍厚。
        color: Colors.black, // 设置文字颜色。
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
      fillColor: const Color.fromRGBO(255, 255, 255, 1), // 设置输入框的背景颜色。
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 设置输入框的圆角度。
        borderSide: BorderSide.none, // 设置输入框的边框为无。
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(0, 122, 255, 1), // 设置输入框在获得焦点时的边框颜色。
          width: 2, // 设置边框宽度。
        ),
      ),
    ),
  );

  /// 返回一个基于Ionic风格的深色主题样式。
  static ThemeData get ionicDarkTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(10, 132, 255, 1), // 设置主要颜色。
    primaryColorLight: const Color.fromRGBO(64, 156, 255, 1), // 设置浅色主要颜色。
    primaryColorDark: const Color.fromRGBO(0, 95, 204, 1), // 设置深色主要颜色。
    brightness: Brightness.dark, // 设置亮度为暗色。
    primarySwatch: Colors.blue, // 设置主色的色标。
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(10, 132, 255, 1), // 设置凸起按钮的背景颜色。
        textStyle: const TextStyle(color: Colors.white), // 设置按钮文字的样式。
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 设置边框圆角度。
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(28, 28, 30, 1), // 设置画布颜色。
    cardColor: const Color.fromRGBO(44, 44, 46, 1), // 设置卡片颜色。
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(44, 44, 46, 1), // 设置 AppBar 背景颜色。
      foregroundColor: Colors.white, // 设置 AppBar 文字颜色。
      elevation: 1, // 设置阴影度。
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(44, 44, 46, 1), // 设置底部导航栏背景颜色。
      selectedItemColor: Color.fromRGBO(10, 132, 255, 1), // 设置选中项的颜色。
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1), // 设置未选中项的颜色。
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, // 设置展示大尺寸文字的字号。
        fontWeight: FontWeight.bold, // 设置字体稍厚。
        color: Colors.white, // 设置文字颜色。
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
      fillColor: const Color.fromRGBO(44, 44, 46, 1), // 设置输入框的背景颜色。
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 设置输入框的圆角度。
        borderSide: BorderSide.none, // 设置输入框的边框为无。
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(10, 132, 255, 1), // 设置输入框在获得焦点时的边框颜色。
          width: 2, // 设置边框宽度。
        ),
      ),
    ),
  );

  /// 返回一个基于Material风格的浅色主题样式。
  static ThemeData get materialLightTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(25, 118, 210, 1), // 设置主要颜色。
    primaryColorLight: const Color.fromRGBO(144, 202, 249, 1), // 设置浅色主要颜色。
    primaryColorDark: const Color.fromRGBO(21, 101, 192, 1), // 设置深色主要颜色。
    brightness: Brightness.light, // 设置亮度为亮色。
    primarySwatch: Colors.blue, // 设置主色的色标。
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(25, 118, 210, 1), // 设置凸起按钮的背景颜色。
        textStyle: const TextStyle(color: Colors.white), // 设置按钮文字的样式。
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 设置边框圆角度。
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(245, 245, 245, 1), // 设置画布颜色。
    cardColor: const Color.fromRGBO(255, 255, 255, 1), // 设置卡片颜色。
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1), // 设置 AppBar 背景颜色。
      foregroundColor: Colors.black, // 设置 AppBar 文字颜色。
      elevation: 1, // 设置阴影度。
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1), // 设置底部导航栏背景颜色。
      selectedItemColor: Color.fromRGBO(25, 118, 210, 1), // 设置选中项的颜色。
      unselectedItemColor: Color.fromRGBO(158, 158, 158, 1), // 设置未选中项的颜色。
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, // 设置展示大尺寸文字的字号。
        fontWeight: FontWeight.bold, // 设置字体稍厚。
        color: Colors.black, // 设置文字颜色。
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
      fillColor: const Color.fromRGBO(255, 255, 255, 1), // 设置输入框的背景颜色。
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 设置输入框的圆角度。
        borderSide: BorderSide.none, // 设置输入框的边框为无。
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(25, 118, 210, 1), // 设置输入框在获得焦点时的边框颜色。
          width: 2, // 设置边框宽度。
        ),
      ),
    ),
  );

  // 返回一个基于Material风格的深色主题样式
  static ThemeData get materialDarkTheme => ThemeData(
    fontFamily: 'Helvetica',
    primaryColor: const Color.fromRGBO(33, 150, 243, 1), // 主要颜色
    primaryColorLight: const Color.fromRGBO(100, 181, 246, 1), // 浅色主要颜色
    primaryColorDark: const Color.fromRGBO(25, 118, 210, 1), // 深色主要颜色
    brightness: Brightness.dark, // 亮度：暗色
    primarySwatch: Colors.blue, // 主色：蓝色
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(33, 150, 243, 1), // 凸起按钮的背景颜色
        textStyle: const TextStyle(color: Colors.white), // 文字颜色
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 边框圆角
        ),
      ),
    ),
    canvasColor: const Color.fromRGBO(18, 18, 18, 1), // 画布的颜色
    cardColor: const Color.fromRGBO(28, 28, 30, 1), // 卡片颜色
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(28, 28, 30, 1), // AppBar的背景颜色
      foregroundColor: Colors.white, // 前景文字颜色
      elevation: 1, // 阴影
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(28, 28, 30, 1), // 底部导航栏背景色
      selectedItemColor: Color.fromRGBO(33, 150, 243, 1), // 选中项的颜色
      unselectedItemColor: Color.fromRGBO(142, 142, 147, 1), // 未选中项的颜色
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, // 大尺寸文字的字号
        fontWeight: FontWeight.bold, // 字体稍厚
        color: Colors.white, // 文字颜色
      ),
      titleLarge: TextStyle(
        fontSize: 20, // 标题大尺寸字号
        fontWeight: FontWeight.bold, // 字体稍厚
        color: Colors.white, // 文字颜色
      ),
      bodyLarge: TextStyle(
        fontSize: 16, // 主要文字大尺寸
        color: Colors.white70, // 文字颜色，70%亮度的白色
      ),
      bodyMedium: TextStyle(
        fontSize: 14, // 中等文字大尺寸
        color: Colors.white60, // 文字颜色，60%亮度的白色
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(28, 28, 30, 1), // 输入框背景色
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 输入框的圆角
        borderSide: BorderSide.none, // 无边框
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 输入框获得焦点时的圆角
        borderSide: const BorderSide(
          color: Color.fromRGBO(33, 150, 243, 1), // 焦点颜色：蓝色
          width: 2, // 边框宽度
        ),
      ),
    ),
  );
}