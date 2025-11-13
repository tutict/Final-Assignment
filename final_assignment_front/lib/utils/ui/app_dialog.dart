part of 'ui_utils.dart';

/// AppDialog 类包含了应用中使用的各种对话框模板。
/// 它提供了一个统一的接口来显示不同类型的对话框，简化了与用户的交互过程。
class AppDialog {
  static Future<T?> showConfirmDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = '取消',
    String confirmText = '确定',
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onCancelled?.call();
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirmed?.call();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> showFormDialog<T>({
    required BuildContext context,
    required Widget formContent,
    String title = '填写信息',
    String confirmText = '提交',
    String cancelText = '取消',
    VoidCallback? onSubmit,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: formContent,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              onSubmit?.call();
              Navigator.of(ctx).pop();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
