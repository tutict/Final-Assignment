import 'package:final_assignment_front/config/navigation/shell_navigation.dart';
import 'package:flutter/material.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({
    super.key,
    required this.groups,
    required this.activePath,
    required this.collapsed,
    required this.onToggle,
    required this.onSelect,
    required this.brandMark,
    required this.brandTitle,
  });

  final List<ShellNavGroup> groups;
  final String activePath;
  final bool collapsed;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;
  final String brandMark;
  final String brandTitle;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late Map<String, bool> _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = {
      for (final group in widget.groups) group.id: group.initiallyCollapsed,
    };
  }

  @override
  void didUpdateWidget(AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final group in widget.groups) {
      _collapsed.putIfAbsent(group.id, () => group.initiallyCollapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final collapsed = widget.collapsed;

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.brandMark,
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.brandTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                  IconButton(
                    tooltip: collapsed ? '展开侧边栏' : '折叠侧边栏',
                    onPressed: widget.onToggle,
                    icon: Icon(collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                for (final group in widget.groups) ...[
                  if (!collapsed)
                    TextButton(
                      onPressed: () => setState(() => _collapsed[group.id] = !(_collapsed[group.id] ?? false)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.label,
                              style: theme.textTheme.labelMedium?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant),
                            ),
                          ),
                          Icon(
                            (_collapsed[group.id] ?? false) ? Icons.expand_more : Icons.expand_less,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  if (collapsed || !(_collapsed[group.id] ?? false))
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Tooltip(
                          message: collapsed ? item.label : '',
                          child: Material(
                            color: widget.activePath == item.path ? scheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => widget.onSelect(item.path),
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 12),
                                    Icon(
                                      item.icon,
                                      color: widget.activePath == item.path ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                                    ),
                                    if (!collapsed) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            color: widget.activePath == item.path ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                                            fontWeight: widget.activePath == item.path ? FontWeight.w800 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
