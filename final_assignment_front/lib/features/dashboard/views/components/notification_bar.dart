import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:get/get.dart';

class NotificationBar extends StatelessWidget {
  const NotificationBar({
    super.key,
    this.message = "请输入身份证号和驾驶证号以继续",
    this.icon = EvaIcons.alertCircleOutline,
    this.onPressedAction,
    this.actionText = "去输入",
  });

  final String message;
  final IconData icon;
  final VoidCallback? onPressedAction;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color backgroundColor =
        isLight ? Colors.white : theme.colorScheme.surface;
    final Color shadowColor = Colors.black.withOpacity(isLight ? 0.1 : 0.15);
    final Color textColor =
        isLight ? Colors.black87 : theme.colorScheme.onSurface;
    final Color iconColor = isLight
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface.withOpacity(0.7);
    final Color arrowColor = isLight
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius ?? 16),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [Colors.white, Colors.grey[50]!]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.8)
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
        onTap: onPressedAction ??
            () {
              Get.toNamed('/input-credentials');
            },
        borderRadius: BorderRadius.circular(kBorderRadius ?? 16),
        splashColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          // Reduced vertical padding
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // Bolder for clarity
                    color: textColor,
                    letterSpacing: 0.2,
                    fontFamily: 'SimsunExtG',
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
                  onPressed: onPressedAction ??
                      () {
                        Get.toNamed('/input-credentials');
                      },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: arrowColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      EvaIcons.arrowForwardOutline,
                      size: 24, // Match leading icon size
                      color: arrowColor,
                    ),
                  ),
                  tooltip: actionText,
                  splashRadius: 24,
                  splashColor: arrowColor.withOpacity(0.3),
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
