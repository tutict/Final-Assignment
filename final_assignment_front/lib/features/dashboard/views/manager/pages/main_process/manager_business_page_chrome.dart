import 'package:flutter/material.dart';

class ManagerBusinessPageChrome extends StatelessWidget {
  const ManagerBusinessPageChrome({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.visibleCount,
    required this.searchBar,
    required this.child,
    this.isLoading = false,
    this.errorMessage = '',
    this.emptyMessage = '',
    this.emptyIcon,
    this.onRefresh,
    this.onRetry,
    this.onLogin,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int totalCount;
  final int visibleCount;
  final Widget searchBar;
  final Widget child;
  final bool isLoading;
  final String errorMessage;
  final String emptyMessage;
  final IconData? emptyIcon;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;

  bool get _hasError => errorMessage.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ManagerBusinessHeader(
            icon: icon,
            title: title,
            subtitle: subtitle,
            totalCount: totalCount,
            visibleCount: visibleCount,
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(
                alpha: dark ? 0.24 : 0.52,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.outlineVariant.withValues(
                  alpha: dark ? 0.34 : 0.48,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: searchBar,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _ManagerBusinessContentPanel(
              isLoading: isLoading,
              errorMessage: errorMessage,
              emptyMessage: emptyMessage,
              emptyIcon: emptyIcon ?? icon,
              onRetry: onRetry,
              onLogin: onLogin,
              child: child,
            ),
          ),
        ],
      ),
    );

    if (onRefresh == null || isLoading || _hasError) {
      return body;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: scheme.primary,
      backgroundColor: scheme.surfaceContainer,
      child: body,
    );
  }
}

class _ManagerBusinessHeader extends StatelessWidget {
  const _ManagerBusinessHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.visibleCount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int totalCount;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.82 : 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.52),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final heading = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: scheme.primary, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
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
                ),
              ),
            ],
          );

          final summary = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ManagerBusinessPill(label: '全部', value: totalCount.toString()),
              _ManagerBusinessPill(
                label: '当前显示',
                value: visibleCount.toString(),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 12),
                summary,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              summary,
            ],
          );
        },
      ),
    );
  }
}

class _ManagerBusinessContentPanel extends StatelessWidget {
  const _ManagerBusinessContentPanel({
    required this.isLoading,
    required this.errorMessage,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.child,
    this.onRetry,
    this.onLogin,
  });

  final bool isLoading;
  final String errorMessage;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget child;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final normalizedError = normalizeManagerBusinessMessage(errorMessage);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.82 : 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.52),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const ManagerBusinessStateView(
                icon: Icons.sync_rounded,
                message: '正在加载业务数据',
                tone: ManagerBusinessStateTone.neutral,
                busy: true,
              );
            }

            if (normalizedError.isNotEmpty) {
              final needsLogin = managerBusinessMessageNeedsLogin(errorMessage);
              return ManagerBusinessStateView(
                icon: needsLogin
                    ? Icons.lock_outline_rounded
                    : Icons.error_outline_rounded,
                message: normalizedError,
                detail: needsLogin ? '请重新登录普通管理员账号后再访问该业务。' : '请检查筛选条件或稍后重试。',
                tone: needsLogin
                    ? ManagerBusinessStateTone.warning
                    : ManagerBusinessStateTone.error,
                actionLabel: needsLogin
                    ? '重新登录'
                    : onRetry == null
                        ? null
                        : '重试',
                onAction: needsLogin ? onLogin : onRetry,
              );
            }

            if (emptyMessage.trim().isNotEmpty) {
              return ManagerBusinessStateView(
                icon: emptyIcon,
                message: normalizeManagerBusinessMessage(emptyMessage),
                detail: '业务数据同步后会显示在这里。',
                tone: ManagerBusinessStateTone.neutral,
              );
            }

            return child;
          },
        ),
      ),
    );
  }
}

enum ManagerBusinessStateTone { neutral, warning, error, success }

class ManagerBusinessStateView extends StatelessWidget {
  const ManagerBusinessStateView({
    super.key,
    required this.icon,
    required this.message,
    required this.tone,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.busy = false,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final ManagerBusinessStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (tone) {
      ManagerBusinessStateTone.neutral => scheme.primary,
      ManagerBusinessStateTone.warning => const Color(0xFFEAB45C),
      ManagerBusinessStateTone.error => scheme.error,
      ManagerBusinessStateTone.success => const Color(0xFF41B86A),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (detail != null && detail!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.42,
                    letterSpacing: 0,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerBusinessPill extends StatelessWidget {
  const _ManagerBusinessPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

void showManagerBusinessToast(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final normalized = normalizeManagerBusinessMessage(message);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final color = isError ? scheme.error : const Color(0xFF41B86A);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      elevation: 0,
      backgroundColor: Color.lerp(scheme.surface, color, 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.34)),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              normalized.isEmpty ? (isError ? '操作失败' : '操作成功') : normalized,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

bool managerBusinessMessageNeedsLogin(String message) {
  final normalized = normalizeManagerBusinessMessage(message).toLowerCase();
  return normalized.contains('未授权') ||
      normalized.contains('登录') ||
      normalized.contains('权限不足') ||
      normalized.contains('403') ||
      normalized.contains('401') ||
      normalized.contains('forbidden');
}

String normalizeManagerBusinessMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return '';

  final normalized = trimmed
      .replaceAll('AppException(forbidden): Forbidden', '权限不足')
      .replaceAll('AppException(forbidden):', '权限不足')
      .replaceAll('Forbidden.', '权限不足')
      .replaceAll('Forbidden', '权限不足')
      .replaceAll('Exception:', '')
      .trim();

  return normalized.isEmpty ? trimmed : normalized;
}
