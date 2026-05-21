part of '../user_dashboard.dart';

class UserSidebar extends StatefulWidget {
  const UserSidebar({super.key});

  @override
  State<UserSidebar> createState() => _UserSidebarState();
}

class _UserSidebarState extends State<UserSidebar> {
  int _selectedIndex = 0;

  List<SelectionButtonData> get _items => [
        SelectionButtonData(
          activeIcon: EvaIcons.grid,
          icon: EvaIcons.gridOutline,
          label: '主页',
          routeName: 'homePage',
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.calendar,
          icon: EvaIcons.calendarOutline,
          label: '业务办理',
          routeName: Routes.businessProgress,
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.email,
          icon: EvaIcons.emailOutline,
          label: '进度消息',
          routeName: Routes.onlineProcessingProgress,
        ),
      ];

  void _select(UserDashboardController controller, int index) {
    final item = _items[index];
    developer.log(
      'index: $index | label: ${item.label} | route: ${item.routeName}',
    );
    setState(() => _selectedIndex = index);

    if (item.routeName == 'homePage') {
      controller.exitSidebarContent();
    } else {
      controller.navigateToPage(item.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserDashboardController controller =
        Get.find<UserDashboardController>();

    return Obx(() {
      final ThemeData currentTheme = controller.currentBodyTheme.value;
      final scheme = currentTheme.colorScheme;
      final dark = currentTheme.brightness == Brightness.dark;
      final collapsed = !ResponsiveBuilder.isMobile(context) &&
          controller.isSidebarCollapsed.value;
      final Color backgroundColor = scheme.surface.withValues(
        alpha: dark ? 0.88 : 0.98,
      );
      final Color dividerColor = scheme.outlineVariant.withValues(
        alpha: dark ? 0.36 : 0.55,
      );

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        color: backgroundColor,
        child: DefaultTextStyle(
          style: TextStyle(color: scheme.onSurface),
          child: IconTheme(
            data: IconThemeData(color: scheme.onSurface),
            child: Column(
              children: [
                _UserSidebarHandle(
                  collapsed: collapsed,
                  onPressed: controller.toggleSidebarCollapsed,
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 10 : 14,
                      vertical: 6,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _UserSidebarItem(
                        item: item,
                        collapsed: collapsed,
                        selected: index == _selectedIndex,
                        onTap: () => _select(controller, index),
                      );
                    },
                  ),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                if (!collapsed)
                  Padding(
                    padding: const EdgeInsets.all(kSpacing),
                    child: PostCard(
                      backgroundColor: scheme.surfaceContainerHighest
                          .withValues(alpha: dark ? 0.34 : 0.42),
                      onPressed: () {},
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  Tooltip(
                    message: '交通安全时时不忘',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: dark ? 0.36 : 0.62,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _UserSidebarHandle extends StatelessWidget {
  const _UserSidebarHandle({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 14),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.end,
          children: [
            Tooltip(
              message: collapsed ? '展开侧边栏' : '折叠侧边栏',
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSidebarItem extends StatelessWidget {
  const _UserSidebarItem({
    required this.item,
    required this.collapsed,
    required this.selected,
    required this.onTap,
  });

  final SelectionButtonData item;
  final bool collapsed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    final background = selected
        ? scheme.primaryContainer.withValues(alpha: dark ? 0.36 : 0.58)
        : Colors.transparent;
    final borderColor = selected
        ? scheme.primary.withValues(alpha: dark ? 0.52 : 0.42)
        : Colors.transparent;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            selected ? item.activeIcon : item.icon,
            color: foreground,
            size: 24,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: collapsed ? item.label : '',
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: scheme.primary.withValues(alpha: 0.10),
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          child: content,
        ),
      ),
    );
  }
}
