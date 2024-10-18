// 定义应用常量库
library app_constants;

// 导入Flutter的Cupertino组件库
import 'package:flutter/cupertino.dart';

// 分割文件引用，专用于API路径常量
part 'api_path.dart';

// 分割文件引用，专用于资源路径常量
part 'assets_path.dart';

// 定义全局边框圆角半径常量
const kBorderRadius = 20.0;

// 定义全局间距常量
const kSpacing = 20.0;

// 定义字体颜色集合，用于不同场景的字体颜色配置
const kFontColorPallets = [
  Color.fromRGBO(255, 255, 255, 1), // 白色
  Color.fromRGBO(210, 210, 210, 1), // 浅灰色
  Color.fromRGBO(170, 170, 170, 1), // 深灰色
];

// 定义通知颜色，用于应用内通知或提示的背景色
const kNotifColor = Color.fromRGBO(74, 177, 120, 1);
