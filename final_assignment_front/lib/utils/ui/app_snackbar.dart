// 导入相关依赖包
part of 'ui_utils.dart';

/// contains all snackbar templates
/// 该类包含所有的SnackBar模板，用于在应用程序中显示临时消息
class AppSnackbar {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade600,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade600,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blueGrey.shade700,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    String? actionText,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: actionText != null
            ? SnackBarAction(
                label: actionText,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }
}
