import 'package:flutter/material.dart';

class DashboardTopBarActions extends StatelessWidget {
  const DashboardTopBarActions({
    super.key,
    required this.onChatPressed,
    required this.onThemePressed,
    this.chatActive = false,
  });

  static const double buttonExtent = 44;
  static const double spacing = 10;
  static const double totalWidth = buttonExtent * 2 + spacing;

  final VoidCallback onChatPressed;
  final VoidCallback onThemePressed;
  final bool chatActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TopBarActionButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'AI 助手',
          selected: chatActive,
          onPressed: onChatPressed,
        ),
        const SizedBox(width: spacing),
        _TopBarActionButton(
          icon: Icons.brightness_6,
          tooltip: '切换明暗主题',
          onPressed: onThemePressed,
        ),
      ],
    );
  }
}

class _TopBarActionButton extends StatelessWidget {
  const _TopBarActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    final background = selected
        ? scheme.primary.withValues(alpha: dark ? 0.22 : 0.12)
        : Colors.transparent;
    final border = selected
        ? scheme.primary.withValues(alpha: dark ? 0.34 : 0.24)
        : Colors.transparent;
    final overlay = selected
        ? scheme.primary.withValues(alpha: dark ? 0.18 : 0.12)
        : scheme.onSurfaceVariant.withValues(alpha: dark ? 0.12 : 0.08);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: SizedBox.square(
        dimension: DashboardTopBarActions.buttonExtent,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              hoverColor: overlay,
              focusColor: overlay,
              splashColor: scheme.primary.withValues(alpha: 0.14),
              child: Center(
                child: Icon(icon, size: 24, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
