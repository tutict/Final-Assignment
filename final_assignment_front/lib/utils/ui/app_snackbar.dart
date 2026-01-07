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
    ThemeData? theme,
  }) {
    _showSnackBar(
      context,
      message: message,
      theme: theme,
      variant: _SnackbarVariant.success,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
    ThemeData? theme,
  }) {
    _showSnackBar(
      context,
      message: message,
      theme: theme,
      variant: _SnackbarVariant.error,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
    ThemeData? theme,
  }) {
    _showSnackBar(
      context,
      message: message,
      theme: theme,
      variant: _SnackbarVariant.info,
      actionText: actionText,
      onAction: onAction,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    ThemeData? theme,
    _SnackbarVariant variant = _SnackbarVariant.info,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final themeData = theme ?? Theme.of(context);
    final colorScheme = themeData.colorScheme;
    Color backgroundColor;
    Color onColor;
    switch (variant) {
      case _SnackbarVariant.success:
        backgroundColor = colorScheme.primary;
        onColor = colorScheme.onPrimary;
        break;
      case _SnackbarVariant.error:
        backgroundColor = colorScheme.error;
        onColor = colorScheme.onError;
        break;
      case _SnackbarVariant.info:
        backgroundColor = colorScheme.surfaceContainerHighest;
        onColor = colorScheme.onSurface;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: themeData.textTheme.bodyMedium?.copyWith(color: onColor),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: actionText != null
            ? SnackBarAction(
                label: actionText,
                onPressed: onAction ?? () {},
                textColor: onColor,
              )
            : null,
      ),
    );
  }
}

enum _SnackbarVariant { success, error, info }
