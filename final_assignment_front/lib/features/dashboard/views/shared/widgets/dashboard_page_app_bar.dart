import 'package:flutter/material.dart';

class DashboardPageBarAction {
  const DashboardPageBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
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
    this.elevation = 0,
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
    final dark = theme.brightness == Brightness.dark;
    final iconColor = colorScheme.onSurfaceVariant;
    final backgroundColor =
        theme.scaffoldBackgroundColor.withValues(alpha: dark ? 0.96 : 0.98);
    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: dark ? 0.34 : 0.48,
    );

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
          tooltip: '刷新',
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
      titleSpacing: leading == null ? 16 : 0,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          letterSpacing: 0,
        ),
      ),
      centerTitle: centerTitle ?? true,
      backgroundColor: backgroundColor,
      foregroundColor: colorScheme.onSurface,
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: iconColor),
      actions: actionWidgets,
      bottom: bottom,
      shape: Border(
        bottom: BorderSide(color: borderColor),
      ),
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
