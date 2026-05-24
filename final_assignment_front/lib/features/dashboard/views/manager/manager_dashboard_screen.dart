import 'dart:developer';
import 'package:final_assignment_front/shared/eva_icons_compat.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/offense_controller.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
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
                _buildManagerOverview(context),
                const SizedBox(height: kSpacing),
                _buildProfileSection(context),
                _buildTeamMemberSection(context),
                _buildProgressSection(context),
                _buildActiveProjectSection(
                  context,
                  crossAxisCount: 1,
                  childAspectRatio: 1.6,
                ),
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

  Widget _buildManagerOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: '管理工作台',
            subtitle: '按今日处理状态、申诉进度和违法分布快速定位待办。',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1000
                  ? 4
                  : width >= 620
                      ? 2
                      : 1;
              final aspectRatio = crossAxisCount == 1 ? 4.2 : 2.6;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: const [
                  DashboardMetricTile(
                    label: '今日违法',
                    value: '15',
                    detail: '实时待核验数据',
                    icon: EvaIcons.alertCircleOutline,
                  ),
                  DashboardMetricTile(
                    label: '已处理',
                    value: '10',
                    detail: '本日完成处理',
                    icon: EvaIcons.checkmarkCircle2Outline,
                  ),
                  DashboardMetricTile(
                    label: '待处理',
                    value: '5',
                    detail: '需要管理端跟进',
                    icon: EvaIcons.clockOutline,
                  ),
                  DashboardMetricTile(
                    label: '申诉完成',
                    value: '60%',
                    detail: '4 / 7 项完成',
                    icon: EvaIcons.trendingUpOutline,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
                      tooltipRoundedRadius: 8,
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
                      tooltipRoundedRadius: 8,
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
