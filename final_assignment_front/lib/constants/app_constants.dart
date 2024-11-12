// 应用常量库定义
library app_constants;

// 导入Flutter的Cupertino组件库和Material组件库
import 'package:flutter/material.dart';

// 分割文件引用，专用于API路径常量
part 'api_path.dart';

// 分割文件引用，专用于资源路径常量
part 'assets_path.dart';

// 全局边框圆角半径常量
const double kBorderRadius = 16.0;

// 全局间距常量
const double kSpacing = 16.0;

// 全局动画持续时间常量
const Duration kAnimationDuration = Duration(milliseconds: 300);

// 字体颜色集合，用于不同场景的字体颜色配置
const List<Color> kFontColorPallets = [
  Color.fromRGBO(255, 255, 255, 1), // 白色
  Color.fromRGBO(230, 230, 230, 1), // 浅灰色
  Color.fromRGBO(170, 170, 170, 1), // 中灰色
  Color.fromRGBO(100, 100, 100, 1), // 深灰色
];

// 通知颜色，用于应用内通知或提示的背景色
const Color kNotifColor = Color.fromRGBO(74, 177, 120, 1);

// 全局阴影效果
const List<BoxShadow> kBoxShadows = [
  BoxShadow(
    color: Colors.black12,
    offset: Offset(0, 4),
    blurRadius: 8,
  ),
];

// 全局文本样式集合
const TextStyle kTitleTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black54,
);

// 全局按钮样式
final ButtonStyle kButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kNotifColor,
  padding: const EdgeInsets.symmetric(horizontal: kSpacing * 2, vertical: kSpacing),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kBorderRadius),
  ),
);

// 全局输入框装饰样式
const InputDecoration kInputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing / 2),
  hintStyle: TextStyle(color: Colors.grey),
);
