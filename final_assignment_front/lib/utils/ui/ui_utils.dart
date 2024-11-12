// 定义一个包含UI相关实用工具的库
library ui_utils;

// 导入处理底部弹出窗口的文件
part 'app_bottomshet.dart';

// 导入处理对话框的文件
part 'app_dialog.dart';

// 导入处理SnackBar的文件
part 'app_snackbar.dart';

class UiUtils {}
// 在本文件中，我们将专注于为某些小部件添加扩展方法
// 例如，下面是一个为TextStyle类添加扩展方法的示例
// 此扩展方法主要用于创建一个适用于输入表头的文本样式
// 它通过复制当前TextStyle的属性，然后修改字体权重、大小和颜色来实现
// 注意：此代码段被注释掉，表示它是一个示例，实际代码中可能并未使用此扩展方法
// Example :
// extension TextStyleExtension on TextStyle {
//   TextStyle inputHeader() {
//     return this.copyWith(
//         fontWeight: FontWeight.bold,
//         fontSize: 16,
//         color: AppTheme.fontPrimaryColorLight);
//   }
// }
