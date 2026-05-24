part of '../manager_dashboard_screen.dart';

class _Sidebar extends StatefulWidget {
  const _Sidebar();

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  int _selectedIndex = 0;
  bool _showExpandedContent = true;
  int _sidebarTransitionToken = 0;
  Worker? _sidebarCollapseWorker;

  List<SelectionButtonData> get _items => [
        SelectionButtonData(
          activeIcon: EvaIcons.grid,
          icon: EvaIcons.gridOutline,
          label: '\u4e3b\u9875',
          routeName: 'homePage',
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.calendar,
          icon: EvaIcons.calendarOutline,
          label: '\u4e1a\u52a1\u5904\u7406',
          routeName: Routes.managerBusinessProcessing,
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.email,
          icon: EvaIcons.emailOutline,
          label: '\u6d88\u606f',
          routeName: Routes.progressManagement,
        ),
      ];

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ManagerDashboardController>();
    _showExpandedContent = !controller.isSidebarCollapsed.value;
    _sidebarCollapseWorker = ever<bool>(
      controller.isSidebarCollapsed,
      _syncExpandedContent,
    );
  }

  @override
  void dispose() {
    _sidebarCollapseWorker?.dispose();
    super.dispose();
  }

  void _syncExpandedContent(bool collapsed) {
    final token = ++_sidebarTransitionToken;

    if (collapsed) {
      if (_showExpandedContent && mounted) {
        setState(() => _showExpandedContent = false);
      }
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (!mounted || token != _sidebarTransitionToken) return;
      final controller = Get.find<ManagerDashboardController>();
      if (!controller.isSidebarCollapsed.value && !_showExpandedContent) {
        setState(() => _showExpandedContent = true);
      }
    });
  }

  void _select(ManagerDashboardController controller, int index) {
    final item = _items[index];
    AppLogger.debug('index : $index | label : ${item.label}');
    setState(() => _selectedIndex = index);

    if (item.routeName == 'homePage') {
      controller.exitSidebarContent();
    } else {
      controller.navigateToPage(item.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ManagerDashboardController controller =
        Get.find<ManagerDashboardController>();

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

      return LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth =
              constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
          final effectiveCollapsed =
              collapsed || !_showExpandedContent || sidebarWidth < 180;
          final showExpandedFooter = !effectiveCollapsed &&
              _showExpandedContent &&
              sidebarWidth >= 220;

          return ClipRect(
            child: ColoredBox(
              color: backgroundColor,
              child: DefaultTextStyle(
                style: TextStyle(color: scheme.onSurface),
                child: IconTheme(
                  data: IconThemeData(color: scheme.onSurface),
                  child: Column(
                    children: [
                      _SidebarHandle(
                        collapsed: collapsed,
                        onPressed: controller.toggleSidebarCollapsed,
                      ),
                      Divider(height: 1, thickness: 1, color: dividerColor),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: effectiveCollapsed ? 10 : 14,
                            vertical: 6,
                          ),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return _ManagerSidebarItem(
                              item: item,
                              collapsed: effectiveCollapsed,
                              selected: index == _selectedIndex,
                              onTap: () => _select(controller, index),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          effectiveCollapsed ? 16 : 14,
                          0,
                          effectiveCollapsed ? 16 : 14,
                          12,
                        ),
                        child: SidebarSettingsButton(
                          collapsed: effectiveCollapsed,
                          selectedStyle: controller.selectedStyle.value,
                          themeMode: controller.currentTheme.value,
                          onThemeSelected: controller.setDashboardTheme,
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: dividerColor),
                      if (showExpandedFooter)
                        Padding(
                          padding: const EdgeInsets.all(kSpacing),
                          child: PoliceCard(
                            backgroundColor: Colors.transparent,
                            onPressed: () {},
                          ),
                        )
                      else ...[
                        const SizedBox(height: 12),
                        Tooltip(
                          message:
                              '\u6267\u6cd5\u4e3a\u6c11 \u516c\u6b63\u5ec9\u6d01',
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
                              Icons.verified_user_outlined,
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
            ),
          );
        },
      );
    });
  }
}

class _SidebarHandle extends StatelessWidget {
  const _SidebarHandle({
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
              message: collapsed
                  ? '\u5c55\u5f00\u4fa7\u8fb9\u680f'
                  : '\u6298\u53e0\u4fa7\u8fb9\u680f',
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

class _ManagerSidebarItem extends StatelessWidget {
  const _ManagerSidebarItem({
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
