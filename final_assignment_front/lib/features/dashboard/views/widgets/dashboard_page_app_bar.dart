import 'package:flutter/material.dart';

class DashboardPageBarAction {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  const DashboardPageBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });
}

class DashboardPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DashboardPageAppBar({
    super.key,
    required this.theme,
    required this.title,
    this.leading,
    this.actions = const [],
    this.onRefresh,
    this.onThemeToggle,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation = 2,
    this.centerTitle,
  });

  final ThemeData theme;
  final String title;
  final Widget? leading;
  final List<DashboardPageBarAction> actions;
  final VoidCallback? onRefresh;
  final VoidCallback? onThemeToggle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onPrimaryContainer;

    final actionWidgets = <Widget>[
      for (final action in actions)
        IconButton(
          icon: Icon(action.icon, color: action.color ?? iconColor),
          tooltip: action.tooltip,
          onPressed: action.onPressed,
        ),
      if (onRefresh != null)
        IconButton(
          icon: Icon(Icons.refresh, color: iconColor),
          tooltip: '刷新列表',
          onPressed: onRefresh,
        ),
      if (onThemeToggle != null)
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode,
            color: iconColor,
          ),
          tooltip: '切换主题',
          onPressed: onThemeToggle,
        ),
    ];

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: elevation,
      actions: actionWidgets,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
