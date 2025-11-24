import 'package:final_assignment_front/features/dashboard/views/widgets/dashboard_page_app_bar.dart';
import 'package:flutter/material.dart';

class UserPageBarAction extends DashboardPageBarAction {
  const UserPageBarAction({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.color,
  });
}

class UserPageAppBar extends DashboardPageAppBar {
  const UserPageAppBar({
    super.key,
    required ThemeData theme,
    required String title,
    Widget? leading,
    List<UserPageBarAction> actions = const [],
    VoidCallback? onRefresh,
    VoidCallback? onThemeToggle,
    bool automaticallyImplyLeading = true,
  }) : super(
          theme: theme,
          title: title,
          leading: leading,
          actions: actions,
          onRefresh: onRefresh,
          onThemeToggle: onThemeToggle,
          automaticallyImplyLeading: automaticallyImplyLeading,
        );
}
