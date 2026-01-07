import 'dart:developer' as developer;
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 数据模型，包含通知栏的配置信息，支持 const 构造函数
class NotificationBarData {
  final String message;
  final IconData icon;
  final String actionText;
  final String routeName;

  const NotificationBarData({
    required this.message,
    required this.icon,
    required this.actionText,
    required this.routeName,
  });
}

// 导航函数，处理页面跳转
void navigateToPage(String routeName) {
  developer.log('Navigating to route: $routeName');
  try {
    Get.toNamed(routeName);
  } catch (e) {
    developer.log('Navigation error: $e', stackTrace: StackTrace.current);
    Get.snackbar('错误', '无法导航到目标页面，请重试');
  }
}

class NotificationBar extends StatelessWidget {
  const NotificationBar({
    super.key,
    this.data = const NotificationBarData(
      message: "请输入身份证号和驾驶证号以继续",
      icon: EvaIcons.alertCircleOutline,
      actionText: "去输入",
      routeName: Routes.personalMain,
    ),
    this.onPressedAction,
  });

  final NotificationBarData data;
  final VoidCallback? onPressedAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color shadowColor = Colors.black.withValues(alpha: isLight ? 0.1 : 0.15);
    final Color textColor =
        isLight ? Colors.black87 : theme.colorScheme.onSurface;
    final Color iconColor = isLight
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final Color arrowColor = isLight
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [Colors.white, Colors.grey[50]!]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressedAction ?? () => navigateToPage(data.routeName),
        borderRadius: BorderRadius.circular(kBorderRadius),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            children: [
              Icon(
                data.icon,
                size: 24,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.message,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed:
                      onPressedAction ?? () => navigateToPage(data.routeName),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: arrowColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      EvaIcons.arrowForwardOutline,
                      size: 24,
                      color: arrowColor,
                    ),
                  ),
                  tooltip: data.actionText,
                  splashRadius: 24,
                  splashColor: arrowColor.withValues(alpha: 0.3),
                  highlightColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
