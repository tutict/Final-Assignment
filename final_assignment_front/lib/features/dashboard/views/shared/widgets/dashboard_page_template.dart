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
        backgroundColor: backgroundColor ?? theme.colorScheme.surface,
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
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary),
            ),
          );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Center(
        child: Text(
          errorMessage!.trim(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (showEmptyState && emptyState != null) {
      return emptyState!;
    }

    return body;
  }
}
