import 'dart:developer';
import 'package:final_assignment_front/shared/eva_icons_compat.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/offense_controller.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/active_project_card.dart'
    hide kSpacing, kBorderRadius;
import 'package:final_assignment_front/features/dashboard/views/shared/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/profile_tile.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_top_bar_actions.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/sidebar_settings_button.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/offense_screen.dart';
import 'package:final_assignment_front/shared_components/offense_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared/widgets/index.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/navigation/page_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'dart:math' as math;

part 'components/header.dart';

part 'components/overview_header.dart';

part 'components/sidebar.dart';

part 'components/team_member.dart';

class DashboardScreen extends GetView<ManagerDashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.pageResolver ??= resolveDashboardPage;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double expandedSidebarWidth =
        (screenWidth * 0.2).clamp(260.0, 320.0).toDouble();
    const double kHeaderTotalHeight = 112;

    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kHeaderTotalHeight),
            child: Builder(
              builder: (context) => _buildHeaderSection(context, screenWidth),
            ),
          ),
          body: Builder(
            builder: (context) => Material(
              color: themeData.scaffoldBackgroundColor,
              child: ResponsiveBuilder(
                mobileBuilder: (context, constraints) {
                  return DashboardBackdrop(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: _buildLayout(context),
                        ),
                        Obx(() => _buildSidebar(context)),
                        _buildResponsiveChatDrawer(context, screenWidth),
                      ],
                    ),
                  );
                },
                tabletBuilder: (context, constraints) {
                  return DashboardBackdrop(
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: controller.isSidebarCollapsed.value
                                    ? 76.0
                                    : screenWidth * 0.3,
                                child: const ClipRect(child: _Sidebar()),
                              ),
                            ),
                            Expanded(child: _buildScrollableLayout(context)),
                          ],
                        ),
                        _buildResponsiveChatDrawer(context, screenWidth),
                      ],
                    ),
                  );
                },
                desktopBuilder: (context, constraints) {
                  final theme = Theme.of(context);
                  return DashboardBackdrop(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: controller.isSidebarCollapsed.value
                                ? 76.0
                                : expandedSidebarWidth,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.96),
                              border: Border(
                                right: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            child: const ClipRect(child: _Sidebar()),
                          ),
                        ),
                        Expanded(
                          child: _buildScrollableLayout(
                            context,
                            isDesktop: true,
                          ),
                        ),
                        Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: controller.isChatExpanded.value
                                ? (screenWidth * 0.3 > 150
                                    ? screenWidth * 0.3
                                    : 150)
                                : 0,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.96),
                              border: Border(
                                left: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            child: controller.isChatExpanded.value
                                ? _buildSideContent(context)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSideContent(BuildContext context) {
    return const AiChat();
  }

  Widget _buildResponsiveChatDrawer(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final availableWidth = math.max(260.0, screenWidth - 24);
    final targetWidth =
        screenWidth < 700 ? screenWidth * 0.92 : screenWidth * 0.46;
    final drawerWidth = math.min(targetWidth, math.min(420.0, availableWidth));

    return Obx(() {
      final expanded = controller.isChatExpanded.value;

      return IgnorePointer(
        ignoring: !expanded,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          opacity: expanded ? 1 : 0,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: controller.toggleChat,
                  child: Container(
                    color: Colors.black.withValues(alpha: dark ? 0.34 : 0.18),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: 12,
                right: expanded ? 12 : -drawerWidth - 12,
                bottom: 12,
                width: drawerWidth,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          scheme.surface.withValues(alpha: dark ? 0.98 : 0.99),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(
                          alpha: dark ? 0.42 : 0.58,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: dark ? 0.36 : 0.18),
                          blurRadius: 30,
                          offset: const Offset(-10, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: dark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: scheme.primary,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'AI 助手',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: controller.toggleChat,
                                  icon: Icon(
                                    Icons.close,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  tooltip: '关闭 AI 助手',
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: dark ? 0.36 : 0.55,
                            ),
                          ),
                          const Expanded(child: AiChat()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacing,
        vertical: kSpacing / 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 0.5 : 0.75)),
          Obx(() {
            final pageContent = controller.selectedPage.value;
            if (pageContent != null) {
              return DashboardPanel(
                padding: EdgeInsets.zero,
                height: MediaQuery.of(context).size.height * 0.82,
                child: _buildUserScreenSidebarTools(context),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildManagerWorkbench(context),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScrollableLayout(
    BuildContext context, {
    bool isDesktop = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: _buildLayout(context, isDesktop: isDesktop),
          ),
        );
      },
    );
  }

  Widget _buildManagerWorkbench(BuildContext context) {
    final offenseController = Get.find<OffenseController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Obx(() {
        final offenses = offenseController.offenses.toList(growable: false);
        final isInitialLoading =
            offenseController.isLoading.value && offenses.isEmpty;
        final errorMessage = offenseController.errorMessage.value;

        if (isInitialLoading) {
          return const DashboardPanel(
            height: 360,
            child: LoadingView(message: '正在同步业务数据...'),
          );
        }

        if (errorMessage.isNotEmpty && offenses.isEmpty) {
          return DashboardPanel(
            height: 360,
            child: ErrorStateView(
              message: errorMessage,
              actionLabel: '重新同步',
              onRetry: () {
                offenseController.loadDashboardData();
              },
            ),
          );
        }

        final stats = _createWorkbenchStats(offenses);

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final sideWidth = constraints.maxWidth >= 1180 ? 360.0 : 320.0;

            final sideColumn = Column(
              children: [
                _buildStatusOverview(context, stats),
                const SizedBox(height: 12),
                _buildDistributionPanel(context, stats),
                const SizedBox(height: 12),
                _buildAdminPanel(context, stats),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkbenchHeader(
                  context,
                  stats,
                  loading: offenseController.isLoading.value,
                  onRefresh: () => offenseController.loadDashboardData(),
                ),
                const SizedBox(height: 14),
                _buildMetricsGrid(context, stats),
                const SizedBox(height: 14),
                if (compact)
                  Column(
                    children: [
                      _buildPendingQueue(context, stats),
                      const SizedBox(height: 12),
                      sideColumn,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPendingQueue(context, stats)),
                      const SizedBox(width: 14),
                      SizedBox(width: sideWidth, child: sideColumn),
                    ],
                  ),
                const SizedBox(height: kSpacing),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildWorkbenchHeader(
    BuildContext context,
    _ManagerWorkbenchStats stats, {
    required bool loading,
    required VoidCallback onRefresh,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = controller.currentProfile;

    return DashboardPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '管理工作台',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '按实时违法记录汇总待办、处理进度和业务分布。',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          );

          final adminChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.54),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: profile.photo,
                  backgroundColor: scheme.primaryContainer,
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        controller.roleDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final refreshButton = Tooltip(
            message: '同步最新业务数据',
            child: IconButton.filledTonal(
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: adminChip),
                    const SizedBox(width: 10),
                    refreshButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              adminChip,
              const SizedBox(width: 10),
              refreshButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    _ManagerWorkbenchStats stats,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1120
            ? 4
            : width >= 560
                ? 2
                : 1;
        final aspectRatio = crossAxisCount == 1 ? 4.5 : 2.85;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _buildMetricTile(
              context,
              icon: EvaIcons.alertCircleOutline,
              label: '今日新增',
              value: '${stats.todayCount}',
              detail: '今日进入系统的违法记录',
              accent: Theme.of(context).colorScheme.primary,
            ),
            _buildMetricTile(
              context,
              icon: EvaIcons.clockOutline,
              label: '待处理',
              value: '${stats.pendingCount}',
              detail: '需要管理员继续跟进',
              accent: const Color(0xFFFFB020),
            ),
            _buildMetricTile(
              context,
              icon: EvaIcons.checkmarkCircle2Outline,
              label: '已办结',
              value: '${stats.completedCount}',
              detail: '已处理、关闭或申诉完成',
              accent: const Color(0xFF34C759),
            ),
            _buildMetricTile(
              context,
              icon: EvaIcons.trendingUpOutline,
              label: '罚款合计',
              value: _formatCurrency(stats.totalFine),
              detail: '累计扣分 ${stats.totalPoints} 分',
              accent: const Color(0xFF4DA3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String detail,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
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
      ),
    );
  }

  Widget _buildPendingQueue(
    BuildContext context,
    _ManagerWorkbenchStats stats,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DashboardPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardSectionHeader(
                  title: '待办队列',
                  subtitle: stats.queueItems.isEmpty
                      ? '暂无需要处理的违法记录。'
                      : '优先显示未处理、处理中和申诉中的记录。',
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  controller.navigateToPage(Routes.managerBusinessProcessing);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('进入业务'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.queueItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.42),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 36,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '当前没有待处理事项',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.totalCount == 0
                        ? '业务数据同步后，这里会显示管理员需要跟进的记录。'
                        : '现有记录已处理完毕，可从业务处理页查看历史数据。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.queueItems.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.36),
              ),
              itemBuilder: (context, index) {
                return _buildQueueItem(context, stats.queueItems[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, OffenseInformation offense) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(context, offense.processStatus);
    final title = _firstNonEmpty([
      offense.driverName,
      offense.licensePlate,
      offense.offenseNumber,
      '未命名记录',
    ]);
    final description = _firstNonEmpty([
      offense.offenseDescription,
      offense.offenseType,
      offense.offenseLocation,
      '暂无违法描述',
    ]);
    final place = _firstNonEmpty([
      offense.offenseLocation,
      offense.offenseCity,
      offense.offenseProvince,
      '地点未登记',
    ]);
    final time = _formatShortTime(offense.offenseTime ?? offense.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            controller.navigateToPage(Routes.managerBusinessProcessing),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.28)),
                ),
                child: Icon(
                  Icons.assignment_late_outlined,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        _buildStatusChip(
                          context,
                          _statusLabel(offense.processStatus),
                          statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildMetaText(context, Icons.place_outlined, place),
                        _buildMetaText(context, Icons.schedule_rounded, time),
                        _buildMetaText(
                          context,
                          Icons.payments_outlined,
                          _formatCurrency(offense.fineAmount ?? 0),
                        ),
                        _buildMetaText(
                          context,
                          Icons.rule_rounded,
                          '${offense.deductedPoints ?? 0} 分',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildMetaText(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOverview(
    BuildContext context,
    _ManagerWorkbenchStats stats,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final processedRate =
        stats.totalCount == 0 ? 0.0 : stats.completedCount / stats.totalCount;

    return DashboardPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: '处理概览',
            subtitle: '来自当前违法记录的实时状态。',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: processedRate,
                      strokeWidth: 8,
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      color: scheme.primary,
                    ),
                    Center(
                      child: Text(
                        '${(processedRate * 100).round()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildStatusLine(
                      context,
                      '待处理',
                      stats.pendingCount,
                      const Color(0xFFFFB020),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusLine(
                      context,
                      '已办结',
                      stats.completedCount,
                      const Color(0xFF34C759),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusLine(
                      context,
                      '申诉中',
                      stats.appealCount,
                      const Color(0xFF4DA3FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          '$value',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionPanel(
    BuildContext context,
    _ManagerWorkbenchStats stats,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = stats.typeDistribution.isEmpty
        ? 1
        : stats.typeDistribution.values.reduce((left, right) {
            return left > right ? left : right;
          });

    return DashboardPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: '违法类型分布',
            subtitle: '按记录类型聚合，最多显示前 5 类。',
          ),
          const SizedBox(height: 14),
          if (stats.typeDistribution.isEmpty)
            Text(
              '暂无可统计的违法类型。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
            )
          else
            ...stats.typeDistribution.entries.map((entry) {
              final ratio = entry.value / maxValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: ratio,
                        backgroundColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.7),
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAdminPanel(
    BuildContext context,
    _ManagerWorkbenchStats stats,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = controller.currentProfile;

    return DashboardPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: '当前管理员',
            subtitle: '用于确认当前数据权限和业务入口。',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: profile.photo,
                backgroundColor: scheme.primaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email,
                      maxLines: 1,
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
          ),
          const SizedBox(height: 14),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.42)),
          const SizedBox(height: 10),
          _buildAdminFact(context, '角色', controller.roleDisplayName),
          const SizedBox(height: 8),
          _buildAdminFact(context, '总记录', '${stats.totalCount} 条'),
          const SizedBox(height: 8),
          _buildAdminFact(context, '最近同步', _formatShortTime(DateTime.now())),
        ],
      ),
    );
  }

  Widget _buildAdminFact(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  _ManagerWorkbenchStats _createWorkbenchStats(
    List<OffenseInformation> offenses,
  ) {
    final now = DateTime.now();
    final sorted = [...offenses]..sort((left, right) {
        return _offenseSortTime(right).compareTo(_offenseSortTime(left));
      });

    final queue = sorted
        .where((item) {
          return _isPendingStatus(item.processStatus);
        })
        .take(6)
        .toList(growable: false);

    final typeCount = <String, int>{};
    var todayCount = 0;
    var pendingCount = 0;
    var completedCount = 0;
    var appealCount = 0;
    var totalFine = 0.0;
    var totalPoints = 0;

    for (final offense in offenses) {
      final status = offense.processStatus;
      final type = _firstNonEmpty([
        offense.offenseType,
        offense.offenseDescription,
        '未分类',
      ]);
      typeCount[type] = (typeCount[type] ?? 0) + 1;

      if (_sameDay(offense.offenseTime ?? offense.createdAt, now)) {
        todayCount++;
      }
      if (_isCompletedStatus(status)) {
        completedCount++;
      } else {
        pendingCount++;
      }
      if ((status ?? '').toLowerCase().contains('appeal')) {
        appealCount++;
      }
      totalFine += offense.fineAmount ?? 0;
      totalPoints += offense.deductedPoints ?? 0;
    }

    final typeEntries = typeCount.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final topTypes = Map<String, int>.fromEntries(typeEntries.take(5));

    return _ManagerWorkbenchStats(
      totalCount: offenses.length,
      todayCount: todayCount,
      pendingCount: pendingCount,
      completedCount: completedCount,
      appealCount: appealCount,
      totalFine: totalFine,
      totalPoints: totalPoints,
      queueItems:
          queue.isEmpty ? sorted.take(6).toList(growable: false) : queue,
      typeDistribution: topTypes,
    );
  }

  bool _isPendingStatus(String? status) {
    return !_isCompletedStatus(status);
  }

  bool _isCompletedStatus(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    return value.contains('processed') ||
        value.contains('complete') ||
        value.contains('paid') ||
        value.contains('closed') ||
        value.contains('approved') ||
        value.contains('rejected') ||
        value.contains('cancelled') ||
        value.contains('canceled') ||
        value.contains('已处理') ||
        value.contains('已缴费') ||
        value.contains('已完成') ||
        value.contains('已关闭');
  }

  Color _statusColor(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;
    final value = (status ?? '').trim().toLowerCase();
    if (value.contains('appeal')) return const Color(0xFF4DA3FF);
    if (_isCompletedStatus(status)) return const Color(0xFF34C759);
    if (value.contains('processing')) return scheme.primary;
    return const Color(0xFFFFB020);
  }

  String _statusLabel(String? status) {
    final raw = (status ?? '').trim();
    final value = raw.toLowerCase();
    if (raw.isEmpty) return '未处理';
    if (value == 'unprocessed') return '未处理';
    if (value == 'processing') return '处理中';
    if (value == 'processed') return '已处理';
    if (value == 'appealing') return '申诉中';
    if (value == 'appeal_approved') return '申诉通过';
    if (value == 'appeal_rejected') return '申诉驳回';
    if (value == 'cancelled' || value == 'canceled') return '已取消';
    if (value.contains('paid')) return '已缴费';
    if (value.contains('closed')) return '已关闭';
    return raw;
  }

  DateTime _offenseSortTime(OffenseInformation offense) {
    return offense.createdAt ??
        offense.offenseTime ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _sameDay(DateTime? left, DateTime right) {
    if (left == null) return false;
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _formatShortTime(DateTime? value) {
    if (value == null) return '时间未登记';
    return DateFormat('MM-dd HH:mm').format(value.toLocal());
  }

  String _formatCurrency(num value) {
    if (value == 0) return '¥0';
    return NumberFormat.compactCurrency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: value >= 10000 ? 1 : 0,
    ).format(value);
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  Widget _buildUserScreenSidebarTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Obx(
        () =>
            controller.selectedPage.value ??
            const Center(child: Text('请选择一个页面')),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProgressSection(BuildContext context) {
    const OffenseCardData offenseData = OffenseCardData(
      totalOffenses: 15,
      handledOffenses: 10,
      unhandledOffenses: 5,
      title: "今日交通违法行为",
    );
    const ProgressReportCardData appealData = ProgressReportCardData(
      percent: 0.6,
      title: "案件申诉处理",
      task: 7,
      doneTask: 4,
      undoneTask: 3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacing,
        vertical: kSpacing / 2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const offenseCard = OffenseCard(data: offenseData);
          const appealCard = ProgressReportCard(data: appealData);
          if (constraints.maxWidth < 720) {
            return const Column(
              children: [
                offenseCard,
                SizedBox(height: 12),
                appealCard,
              ],
            );
          }
          return const Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: offenseCard),
              SizedBox(width: kSpacing / 2),
              Expanded(child: appealCard),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTeamMemberSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeamMember(
            totalMember: controller.getMember().length,
            onPressedAdd: () => log("Add member clicked"),
          ),
          const SizedBox(height: kSpacing / 2),
          DashboardPanel(
            padding: const EdgeInsets.all(16),
            child: ListProfilImage(
              maxImages: 6,
              images: controller.getMember(),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActiveProjectSection(
    BuildContext context, {
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
// Height for two stacked charts with titles
    final double gridHeight = MediaQuery.of(context).size.height * 1.0;
    final offenseController = Get.find<OffenseController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: ActiveProjectCard(
        onPressedSeeAll: () {
          NavigationHelper.toNamed(Routes.offenseScreen);
        },
        child: SizedBox(
          height: gridHeight,
          child: Obx(
            () {
              if (offenseController.isLoading.value) {
                return const LoadingView();
              }
              if (offenseController.errorMessage.value.isNotEmpty) {
                return ErrorStateView(
                  message: offenseController.errorMessage.value,
                );
              }

              final offenseTypes = Map<String, int>.from(
                offenseController.offenseTypes,
              );
              final timeSeries = List<Map<String, dynamic>>.from(
                offenseController.timeSeries,
              );
              final startTime = offenseController.startTime.value;

              return GridView.builder(
                itemCount: 2,
                // Only two charts
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: kSpacing,
                  mainAxisSpacing: kSpacing * 1.5,
                  childAspectRatio: childAspectRatio,
                  mainAxisExtent: 330, // Increased for larger charts + title
                ),
                itemBuilder: (context, index) {
                  Widget chart;
                  String title;

                  if (index == 0) {
                    chart = SizedBox(
                      height: 280, // Increased for full visibility
                      child: OffenseBarChart(
                        typeCountMap: offenseTypes,
                        startTime: startTime,
                      ),
                    );
                    title = '违法类型分布';
                  } else {
                    chart = SizedBox(
                      height: 280, // Increased for full visibility
                      child:
                          _buildTimeSeriesChart(context, timeSeries, startTime),
                    );
                    title = '罚款与扣分趋势';
                  }

                  return DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: chart,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSeriesChart(
    BuildContext context,
    List<Map<String, dynamic>> timeSeries,
    DateTime startTime,
  ) {
    if (timeSeries.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('无时间序列数据可用')),
      );
    }

    final theme = Theme.of(context);
    final dataList = timeSeries
        .map((item) => {
              'time': DateTime.parse(item['time']),
              'value1': item['value1'] as num,
              'value2': item['value2'] as num,
            })
        .toList();

    final maxX = dataList
        .map((item) => (item['time'] as DateTime).difference(startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY1 = dataList
        .map((item) => (item['value1'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = dataList
        .map((item) => (item['value2'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxY1 > maxY2 ? maxY1 : maxY2) * 1.2;

// Log chart dimensions for debugging
    log('TimeSeriesChart: maxX=$maxX, maxY=$maxY, dataPoints=${dataList.length}');

    return SizedBox(
      height: 280,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added padding
        child: ClipRect(
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY : 500,
                  minY: 0,
                  barGroups: dataList.asMap().entries.map((entry) {
                    final item = entry.value;
                    final days =
                        (item['time'] as DateTime).difference(startTime).inDays;
                    final value = (item['value1'] as num).toDouble();
                    return BarChartGroupData(
                      x: days,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Reduced for fit
                        interval: maxY / 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12, // Reduced for fit
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32, // Reduced for fit
                        interval: maxX > 7 ? maxX / 7 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final date = startTime.add(Duration(days: index));
                          return Text(
                            DateFormat('MM-dd').format(date),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12, // Reduced for fit
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    verticalInterval: maxX > 7 ? maxX / 7 : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(8),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipColor: (_) => theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.9),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = startTime.add(Duration(days: group.x));
                        return BarTooltipItem(
                          '${DateFormat('yyyy-MM-dd').format(date)}\n罚款: ${rod.toY.toInt()}',
                          TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced for fit
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataList.asMap().entries.map((entry) {
                        final item = entry.value;
                        final days = (item['time'] as DateTime)
                            .difference(startTime)
                            .inDays
                            .toDouble();
                        return FlSpot(days, (item['value1'] as num).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: dataList.asMap().entries.map((entry) {
                        final item = entry.value;
                        final days = (item['time'] as DateTime)
                            .difference(startTime)
                            .inDays
                            .toDouble();
                        return FlSpot(days, (item['value2'] as num).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.secondary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: maxX > 0 ? maxX : 20,
                  minY: 0,
                  maxY: maxY > 0 ? maxY : 500,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(8),
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipColor: (_) => theme
                          .colorScheme.secondaryContainer
                          .withValues(alpha: 0.9),
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((spot) {
                        final date =
                            startTime.add(Duration(days: spot.x.toInt()));
                        final label = spot.barIndex == 0 ? '罚款' : '扣分';
                        return LineTooltipItem(
                          '${DateFormat('yyyy-MM-dd').format(date)}\n$label: ${spot.y.toInt()}',
                          TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced for fit
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final bool isDesktop = ResponsiveBuilder.isDesktop(context);
    final bool showSidebar = isDesktop || controller.isSidebarOpen.value;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.98),
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: showSidebar
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16.0, kSpacing * 2, 16.0, kSpacing),
              child: _Sidebar(),
            )
          : null,
    );
  }

  // ignore: unused_element
  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Obx(() {
        final Profile profile = controller.currentProfile;
        return ProfilTile(
          data: profile,
          onPressedNotification: () => log("Notification clicked"),
          controller: controller,
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.95 : 0.98),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildHeader(
            context: context,
            onPressedMenu: () => controller.openDrawer(),
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    final scheme = Theme.of(context).colorScheme;
    const double horizontalPadding = kSpacing / 2;
    const double mobileBreakpoint = 600.0;

    return SizedBox(
      height: 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double containerWidth =
              constraints.hasBoundedWidth ? constraints.maxWidth : screenWidth;
          final double contentWidth =
              math.max(0, containerWidth - 2 * horizontalPadding);
          final bool showMenu =
              screenWidth < mobileBreakpoint && onPressedMenu != null;
          final bool compactActions = contentWidth < 360;
          final double menuIconWidth = showMenu ? 48.0 : 0.0;
          final double actionsWidth = compactActions
              ? DashboardTopBarActions.compactTotalWidth
              : DashboardTopBarActions.totalWidth;
          final double headerContentWidth = math.max(
            0,
            contentWidth - menuIconWidth - actionsWidth,
          );

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                if (showMenu)
                  IconButton(
                    onPressed: () => controller.toggleSidebar(),
                    icon: Icon(Icons.menu, color: scheme.onSurfaceVariant),
                    tooltip: "菜单",
                  ),
                if (headerContentWidth >= 72)
                  SizedBox(
                    width: headerContentWidth,
                    child: const _Header(),
                  )
                else
                  const Spacer(),
                Obx(
                  () => DashboardTopBarActions(
                    chatActive: controller.isChatExpanded.value,
                    onChatPressed: controller.toggleChat,
                    onThemePressed: controller.toggleBodyTheme,
                    compact: compactActions,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManagerWorkbenchStats {
  const _ManagerWorkbenchStats({
    required this.totalCount,
    required this.todayCount,
    required this.pendingCount,
    required this.completedCount,
    required this.appealCount,
    required this.totalFine,
    required this.totalPoints,
    required this.queueItems,
    required this.typeDistribution,
  });

  final int totalCount;
  final int todayCount;
  final int pendingCount;
  final int completedCount;
  final int appealCount;
  final double totalFine;
  final int totalPoints;
  final List<OffenseInformation> queueItems;
  final Map<String, int> typeDistribution;
}
