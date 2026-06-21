export 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_app_bar.dart';

import 'package:final_assignment_front/features/dashboard/views/user/widgets/user_page_app_bar.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_app_bar.dart';
import 'package:flutter/material.dart';

enum DashboardPageType { manager, user, custom }

class DashboardPageTemplate extends StatelessWidget {
  const DashboardPageTemplate({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    this.pageType = DashboardPageType.manager,
    this.actions = const [],
    this.onRefresh,
    this.onThemeToggle,
    this.padding = const EdgeInsets.all(16),
    this.bodyIsScrollable = false,
    this.safeArea = true,
    this.backgroundColor,
    this.appBar,
    this.isLoading = false,
    this.errorMessage,
    this.showEmptyState = false,
    this.emptyState,
    this.loadingWidget,
    this.centerTitle,
    this.floatingActionButton,
  });

  final ThemeData theme;
  final String title;
  final Widget body;
  final DashboardPageType pageType;
  final List<DashboardPageBarAction> actions;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onThemeToggle;
  final EdgeInsetsGeometry padding;
  final bool bodyIsScrollable;
  final bool safeArea;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool isLoading;
  final String? errorMessage;
  final bool showEmptyState;
  final Widget? emptyState;
  final Widget? loadingWidget;
  final bool? centerTitle;
  final FloatingActionButton? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final pageAppBar = appBar ?? _buildAppBar();
    Widget content = _resolveContent();

    if (padding != EdgeInsets.zero) {
      content = Padding(padding: padding, child: content);
    }

    if (!bodyIsScrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        appBar: pageAppBar,
        floatingActionButton: floatingActionButton,
        body: content,
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (pageType) {
      case DashboardPageType.user:
        final userActions = actions
            .map(
              (action) => UserPageBarAction(
                icon: action.icon,
                onPressed: action.onPressed,
                tooltip: action.tooltip,
                color: action.color,
              ),
            )
            .toList();
        return UserPageAppBar(
          theme: theme,
          title: title,
          actions: userActions,
          onRefresh: onRefresh,
          onThemeToggle: onThemeToggle,
          automaticallyImplyLeading: true,
        );
      case DashboardPageType.manager:
        return DashboardPageAppBar(
          theme: theme,
          title: title,
          actions: actions,
          onRefresh: onRefresh,
          onThemeToggle: onThemeToggle,
          automaticallyImplyLeading: true,
          centerTitle: centerTitle,
        );
      case DashboardPageType.custom:
        return appBar;
    }
  }

  Widget _resolveContent() {
    if (isLoading) {
      return loadingWidget ??
          _StatusFrame(
            minHeightFactor: 0.52,
            child: _PageStatusSurface(
              icon: Icons.sync_rounded,
              title: '正在加载',
              detail: '正在同步页面数据，请稍候。',
              progress: true,
              theme: theme,
            ),
          );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return _StatusFrame(
        minHeightFactor: 0.52,
        child: _PageStatusSurface(
          icon: Icons.error_outline_rounded,
          title: '操作未完成',
          detail: errorMessage!.trim(),
          theme: theme,
          severity: _PageStatusSeverity.error,
          action: onRefresh == null
              ? null
              : OutlinedButton.icon(
                  onPressed: () => onRefresh!(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
        ),
      );
    }

    if (showEmptyState) {
      return emptyState ??
          _StatusFrame(
            minHeightFactor: 0.46,
            child: _PageStatusSurface(
              icon: Icons.inbox_outlined,
              title: '暂无数据',
              detail: '当前筛选条件下没有可显示的记录。',
              theme: theme,
              severity: _PageStatusSeverity.empty,
            ),
          );
    }

    return body;
  }
}

class _StatusFrame extends StatelessWidget {
  const _StatusFrame({
    required this.child,
    this.minHeightFactor = 0.5,
  });

  final Widget child;
  final double minHeightFactor;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * minHeightFactor;
    final constrainedHeight = height.clamp(260.0, 520.0).toDouble();
    return SizedBox(
      width: double.infinity,
      height: constrainedHeight,
      child: Center(child: child),
    );
  }
}

enum _PageStatusSeverity { neutral, error, empty }

class _PageStatusSurface extends StatelessWidget {
  const _PageStatusSurface({
    required this.icon,
    required this.title,
    required this.detail,
    required this.theme,
    this.progress = false,
    this.severity = _PageStatusSeverity.neutral,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final ThemeData theme;
  final bool progress;
  final _PageStatusSeverity severity;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = switch (severity) {
      _PageStatusSeverity.error => scheme.error,
      _PageStatusSeverity.empty => scheme.onSurfaceVariant,
      _PageStatusSeverity.neutral => scheme.primary,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.98),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.38 : 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: dark ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: progress
                  ? Padding(
                      padding: const EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: accent,
                      ),
                    )
                  : Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: severity == _PageStatusSeverity.error
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
