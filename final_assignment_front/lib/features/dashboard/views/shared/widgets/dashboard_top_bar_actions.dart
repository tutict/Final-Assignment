import 'package:final_assignment_front/features/dashboard/views/shared/widgets/unread_message_badge.dart';
import 'package:flutter/material.dart';

class DashboardTopBarActions extends StatelessWidget {
  const DashboardTopBarActions({
    super.key,
    required this.onChatPressed,
    required this.onThemePressed,
    required this.onMessagesPressed,
    required this.onProfilePressed,
    required this.onSettingsPressed,
    required this.onLogoutPressed,
    this.chatActive = false,
    this.compact = false,
  });

  static const double buttonExtent = 44;
  static const double spacing = 8;
  static const int actionCount = 4;
  static const double totalWidth = buttonExtent * actionCount + spacing * (actionCount - 1);
  static const double compactButtonExtent = 40;
  static const double compactSpacing = 6;
  static const double compactTotalWidth =
      compactButtonExtent * actionCount + compactSpacing * (actionCount - 1);

  final VoidCallback onChatPressed;
  final VoidCallback onThemePressed;
  final VoidCallback onMessagesPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onLogoutPressed;
  final bool chatActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actionExtent = compact ? compactButtonExtent : buttonExtent;
    final actionSpacing = compact ? compactSpacing : spacing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _TopBarActionButton(
              icon: Icons.notifications_none_rounded,
              tooltip: '未读消息',
              onPressed: onMessagesPressed,
              dimension: actionExtent,
            ),
            const Positioned(
              right: -2,
              top: -2,
              child: UnreadMessageBadge(),
            ),
          ],
        ),
        SizedBox(width: actionSpacing),
        _TopBarActionButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'AI 助手',
          selected: chatActive,
          onPressed: onChatPressed,
          dimension: actionExtent,
        ),
        SizedBox(width: actionSpacing),
        _TopBarActionButton(
          icon: Icons.brightness_6,
          tooltip: '切换明暗主题',
          onPressed: onThemePressed,
          dimension: actionExtent,
        ),
        SizedBox(width: actionSpacing),
        PopupMenuButton<String>(
          tooltip: '账号菜单',
          onSelected: (value) {
            switch (value) {
              case 'profile':
                onProfilePressed();
              case 'settings':
                onSettingsPressed();
              case 'logout':
                onLogoutPressed();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('个人资料')),
            PopupMenuItem(value: 'settings', child: Text('设置')),
            PopupMenuItem(value: 'logout', child: Text('退出登录')),
          ],
          child: _TopBarActionButton(
            icon: Icons.account_circle_outlined,
            tooltip: '账号菜单',
            onPressed: null,
            dimension: actionExtent,
          ),
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
    required this.dimension,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double dimension;
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
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: SizedBox.square(
          dimension: dimension,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onPressed,
                hoverColor: overlay,
                focusColor: overlay,
                splashColor: scheme.primary.withValues(alpha: 0.14),
                child: Center(
                  child: Icon(
                    icon,
                    size: dimension <= 40 ? 22 : 24,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
