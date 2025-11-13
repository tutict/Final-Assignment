// 定义一个包含UI相关实用工具的库
library ui_utils;

import 'package:flutter/material.dart';

// 导入处理底部弹出窗口的文件
part 'app_bottomshet.dart';

// 导入处理对话框的文件
part 'app_dialog.dart';

// 导入处理SnackBar的文件
part 'app_snackbar.dart';

class UiUtils {}

extension TextStyleExtension on TextStyle {
  TextStyle inputHeader(Color color) {
    return copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: color,
    );
  }
}
