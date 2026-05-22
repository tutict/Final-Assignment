import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum UserBusinessStatusKind { error, empty, info, success }

String normalizeUserBusinessMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return '当前业务暂无可显示的信息';

  final lower = trimmed.toLowerCase();
  if (trimmed.contains('未找到身份证号码')) {
    return '请先完善身份证号和驾驶证号后再办理车辆业务';
  }
  if (trimmed.contains('未登录或未找到驾驶员信息') ||
      trimmed.contains('未找到驾驶员信息') ||
      trimmed.contains('无法获取驾驶员姓名') ||
      trimmed.contains('尚未关联司机档案') ||
      trimmed.contains('尚未关联驾驶员档案')) {
    return '当前账号尚未关联驾驶员档案，请先完善身份证号和驾驶证号';
  }
  if (lower.contains('forbidden') || trimmed.contains('403')) {
    return '权限不足：当前账号暂无访问该业务的权限';
  }
  if (lower.contains('unauthorized') || trimmed.contains('未授权')) {
    return '登录状态已失效，请重新登录';
  }
  if (lower.contains('network request failed') || lower.contains('network')) {
    return '网络连接异常，请检查后端服务和本地网络';
  }
  if (lower.contains('internal server error')) {
    return '服务器处理失败，请稍后重试';
  }
  if (lower.contains('appexception')) {
    return trimmed
        .replaceAll(RegExp(r'AppException\([^)]+\):\s*'), '')
        .replaceAll('Forbidden', '权限不足：当前账号暂无访问该业务的权限');
  }
  return trimmed;
}

bool userBusinessMessageNeedsLogin(String message) {
  final normalized = normalizeUserBusinessMessage(message);
  return normalized.contains('登录状态') ||
      normalized.contains('登录已过期') ||
      normalized.contains('请重新登录') ||
      normalized.contains('未授权');
}

void showUserBusinessToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  String? title,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final dark = theme.brightness == Brightness.dark;
  final background = isError ? scheme.errorContainer : scheme.primaryContainer;
  final foreground =
      isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;

  Get.closeCurrentSnackbar();
  Get.snackbar(
    title ?? (isError ? '操作未完成' : '操作成功'),
    normalizeUserBusinessMessage(message),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 8,
    backgroundColor: background.withValues(alpha: dark ? 0.94 : 0.98),
    colorText: foreground,
    icon: Icon(
      isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
      color: foreground,
    ),
    duration: const Duration(seconds: 3),
  );
}

class UserBusinessPageHeader extends StatelessWidget {
  const UserBusinessPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.accentColor,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Color? accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.34 : 0.58,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.48),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final iconBox = Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: effectiveAccent.withValues(alpha: dark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: effectiveAccent, size: compact ? 20 : 22),
          );
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  fontSize: compact ? 18 : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          );
          final badgeWidget = badge == null
              ? null
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        effectiveAccent.withValues(alpha: dark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(child: titleBlock),
                  ],
                ),
                if (badgeWidget != null || trailing != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (badgeWidget != null) badgeWidget,
                      if (trailing != null) trailing!,
                    ],
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              iconBox,
              const SizedBox(width: 14),
              Expanded(child: titleBlock),
              if (badgeWidget != null) ...[
                const SizedBox(width: 10),
                badgeWidget,
              ],
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class UserBusinessStatusPanel extends StatelessWidget {
  const UserBusinessStatusPanel({
    super.key,
    required this.message,
    this.title,
    this.kind = UserBusinessStatusKind.error,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String message;
  final UserBusinessStatusKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final colors = _StatusColors.resolve(theme, kind);
    final normalizedMessage = normalizeUserBusinessMessage(message);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            final iconBox = Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color: colors.foreground.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconFor(kind),
                color: colors.foreground,
                size: compact ? 20 : 22,
              ),
            );
            final messageBlock = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? _titleFor(kind),
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  normalizedMessage,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.foreground,
                      foregroundColor: colors.onForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            );

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: dark ? 0.24 : 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      colors.foreground.withValues(alpha: dark ? 0.46 : 0.32),
                ),
              ),
              child: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconBox,
                        const SizedBox(height: 12),
                        messageBlock,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        iconBox,
                        const SizedBox(width: 14),
                        Expanded(child: messageBlock),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(UserBusinessStatusKind kind) {
    return switch (kind) {
      UserBusinessStatusKind.error => Icons.error_outline_rounded,
      UserBusinessStatusKind.empty => Icons.inbox_outlined,
      UserBusinessStatusKind.info => Icons.info_outline_rounded,
      UserBusinessStatusKind.success => Icons.check_circle_outline_rounded,
    };
  }

  String _titleFor(UserBusinessStatusKind kind) {
    return switch (kind) {
      UserBusinessStatusKind.error => '业务暂不可用',
      UserBusinessStatusKind.empty => '暂无记录',
      UserBusinessStatusKind.info => '提示',
      UserBusinessStatusKind.success => '处理完成',
    };
  }
}

class UserBusinessRecordCard extends StatefulWidget {
  const UserBusinessRecordCard({
    super.key,
    required this.icon,
    required this.title,
    required this.details,
    this.accentColor,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final List<String> details;
  final Color? accentColor;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<UserBusinessRecordCard> createState() => _UserBusinessRecordCardState();
}

class _UserBusinessRecordCardState extends State<UserBusinessRecordCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = widget.accentColor ?? scheme.primary;
    final background = _hovered
        ? Color.lerp(scheme.surface, accent, dark ? 0.08 : 0.045)!
        : scheme.surface.withValues(alpha: dark ? 0.78 : 0.96);
    final border = _hovered
        ? accent.withValues(alpha: dark ? 0.72 : 0.56)
        : scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.48);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(
                      alpha: _hovered ? (dark ? 0.20 : 0.08) : 0.03,
                    ),
                    blurRadius: _hovered ? 16 : 8,
                    offset: Offset(0, _hovered ? 8 : 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final iconBox = Container(
                    width: compact ? 40 : 44,
                    height: compact ? 40 : 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: accent, size: 22),
                  );
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (widget.badge != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.badge!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      for (final detail in widget.details.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            detail,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0,
                              height: 1.25,
                            ),
                          ),
                        ),
                    ],
                  );
                  final trailing = widget.trailing ??
                      (widget.onTap != null
                          ? Icon(
                              Icons.arrow_forward_rounded,
                              color:
                                  _hovered ? accent : scheme.onSurfaceVariant,
                            )
                          : null);

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            iconBox,
                            const SizedBox(width: 12),
                            Expanded(child: content),
                          ],
                        ),
                        if (trailing != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: trailing,
                          ),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      iconBox,
                      const SizedBox(width: 14),
                      Expanded(child: content),
                      if (trailing != null) ...[
                        const SizedBox(width: 10),
                        trailing,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({
    required this.foreground,
    required this.onForeground,
    required this.background,
  });

  final Color foreground;
  final Color onForeground;
  final Color background;

  static _StatusColors resolve(ThemeData theme, UserBusinessStatusKind kind) {
    final scheme = theme.colorScheme;
    return switch (kind) {
      UserBusinessStatusKind.error => _StatusColors(
          foreground: scheme.error,
          onForeground: scheme.onError,
          background: scheme.errorContainer,
        ),
      UserBusinessStatusKind.empty => _StatusColors(
          foreground: scheme.primary,
          onForeground: scheme.onPrimary,
          background: scheme.primaryContainer,
        ),
      UserBusinessStatusKind.info => _StatusColors(
          foreground: scheme.tertiary,
          onForeground: scheme.onTertiary,
          background: scheme.tertiaryContainer,
        ),
      UserBusinessStatusKind.success => const _StatusColors(
          foreground: Color(0xFF2E7D32),
          onForeground: Colors.white,
          background: Color(0xFFC8E6C9),
        ),
    };
  }
}
