import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: icon ?? Icons.inbox_outlined,
      message: _normalizeMessage(message),
      tone: _StateTone.neutral,
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.actionLabel = '重试',
  });

  final String message;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeMessage(message);
    final forbidden = _isForbiddenMessage(message);

    return _StateShell(
      icon: forbidden ? Icons.lock_outline_rounded : Icons.error_outline,
      message: forbidden ? '权限不足：当前账号无法访问该业务数据' : normalized,
      detail: forbidden ? '请切换到管理员账号，或联系系统管理员检查角色授权。' : null,
      tone: forbidden ? _StateTone.warning : _StateTone.error,
      actionLabel: onRetry == null ? null : actionLabel,
      onAction: onRetry,
    );
  }
}

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, this.hint});

  final String? hint;

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: Icons.lock_outline_rounded,
      message: hint ?? '权限不足：当前账号无法访问该业务数据',
      detail: '请切换到管理员账号，或联系系统管理员检查角色授权。',
      tone: _StateTone.warning,
    );
  }
}

enum _StateTone { neutral, warning, error }

class _StateShell extends StatelessWidget {
  const _StateShell({
    required this.icon,
    required this.message,
    required this.tone,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final _StateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (tone) {
      _StateTone.neutral => scheme.onSurfaceVariant,
      _StateTone.warning => const Color(0xFFFFB4A9),
      _StateTone.error => scheme.error,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.34)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isForbiddenMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('forbidden') ||
      normalized.contains('403') ||
      message.contains('权限不足') ||
      message.contains('没有权限') ||
      message.contains('无权限');
}

String _normalizeMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return '暂无数据';
  if (_isForbiddenMessage(trimmed)) {
    return '权限不足：当前账号无法访问该业务数据';
  }
  return trimmed
      .replaceAll('AppException(forbidden): Forbidden', '权限不足')
      .replaceAll('AppException(forbidden):', '')
      .replaceAll('Forbidden.', '权限不足')
      .replaceAll('Forbidden', '权限不足')
      .trim();
}
