// 定义应用常量库
library app_constants;

// 导入Flutter的Cupertino组件库和Material组件库
import 'package:flutter/material.dart';

// 分割文件引用，专用于API路径常量
part 'api_path.dart';

// 分割文件引用，专用于资源路径常量
part 'assets_path.dart';

// 定义全局边框圆角半径常量
const double kBorderRadius = 16.0;

// 定义全局间距常量
const double kSpacing = 16.0;

// 定义全局动画持续时间常量
const Duration kAnimationDuration = Duration(milliseconds: 300);

// 定义字体颜色集合，用于不同场景的字体颜色配置
const List<Color> kFontColorPallets = [
  Color.fromRGBO(255, 255, 255, 1), // 白色
  Color.fromRGBO(230, 230, 230, 1), // 更浅的灰色
  Color.fromRGBO(170, 170, 170, 1), // 深灰色
  Color.fromRGBO(100, 100, 100, 1), // 更深的灰色
];

// 定义通知颜色，用于应用内通知或提示的背景色
const Color kNotifColor = Color.fromRGBO(74, 177, 120, 1);

// 定义全局阴影效果
const List<BoxShadow> kBoxShadows = [
  BoxShadow(
    color: Colors.black12,
    offset: Offset(0, 4),
    blurRadius: 8,
  ),
];

// 定义全局文本样式集合
const TextStyle kTitleTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black54,
);
