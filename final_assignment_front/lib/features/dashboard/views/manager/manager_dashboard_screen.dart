import 'dart:developer';
import 'dart:ui';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/active_project_card.dart'
    hide kSpacing, kBorderRadius;
import 'package:final_assignment_front/features/dashboard/views/shared/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/profile_tile.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/traffic_violation_screen.dart';
import 'package:final_assignment_front/shared_components/traffic_violation_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/navigation/page_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

part 'components/header.dart';

part 'components/overview_header.dart';


part 'components/sidebar.dart';

part 'components/team_member.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

// Hardcoded traffic violation data
  static final Map<String, dynamic> hardcodedTrafficViolationData = {
    'violationTypes': {
      "超速": 120,
      "闯红灯": 80,
      "违停": 50,
      "酒驾": 20,
      "其他": 30,
    },
    'timeSeries': List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return {
        'time': date.toIso8601String(),
        'value1': 50 + index * 10, // Fines
        'value2': 30 + index * 5, // Points
      };
    }),
    'appealReasons': {
      "证据不足": 50,
      "程序不当": 30,
      "误判": 20,
      "其他": 10,
    },
    'paymentStatus': {
      "已支付": 100,
      "未支付": 50,
    },
  };

  @override
  Widget build(BuildContext context) {
    controller.pageResolver ??= resolveDashboardPage;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    const double kHeaderTotalHeight = 32 + 50 + 15 + 1;

    return Scaffold(
      key: controller.scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kHeaderTotalHeight),
        child: _buildHeaderSection(context, screenWidth),
      ),
      body: Obx(
        () => Theme(
          data: controller.currentBodyTheme.value,
          child: Material(
            child: ResponsiveBuilder(
                    mobileBuilder: (context, constraints) {
                      return Stack(
                        children: [
                          SingleChildScrollView(
                            child: _buildLayout(context),
                          ),
                          Obx(() => _buildSidebar(context)),
                        ],
                      );
                    },
                    tabletBuilder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.3,
                            child:
                                _Sidebar(data: controller.getSelectedProject()),
                          ),
                          SizedBox(
                            width: screenWidth * 0.7,
                            child: SingleChildScrollView(
                              child: _buildLayout(context),
                            ),
                          ),
                        ],
                      );
                    },
                    desktopBuilder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenWidth * 0.2,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).cardColor.withValues(alpha: 0.95),
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(2, 0),
                                ),
                              ],
                            ),
                            child:
                                _Sidebar(data: controller.getSelectedProject()),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                border: Border(
                                  right:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: _buildLayout(context),
                              ),
                            ),
                          ),
                          Obx(
                            () => AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              width: controller.isChatExpanded.value
                                  ? (screenWidth * 0.3 > 150
                                      ? screenWidth * 0.3
                                      : 150)
                                  : 0,
                              height: screenHeight,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .cardColor
                                    .withValues(alpha: 0.95),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(-2, 0),
                                  ),
                                ],
                              ),
                              child: controller.isChatExpanded.value
                                  ? _buildSideContent(context)
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSideContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.3,
        minWidth: 150,
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: const AiChat(),
    );
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacing,
          vertical: kSpacing / 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 0.5 : 0.75)),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            Obx(() {
              final pageContent = controller.selectedPage.value;
              if (pageContent != null) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildUserScreenSidebarTools(context),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(context),
                    _buildTeamMemberSection(context),
                    _buildProgressSection(Axis.horizontal, context),
                    _buildActiveProjectSection(
                      context,
                      crossAxisCount: 1,
                      childAspectRatio: 1.6, // Adjusted for more vertical space
                    ),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUserScreenSidebarTools(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(12.0),
          child: Obx(() {
            final pageContent = controller.selectedPage.value;
            return pageContent ?? const Center(child: Text('请选择一个页面'));
          }),
        ),
      ),
    );
  }

  Widget _buildProgressSection(Axis axis, BuildContext context) {
    const TrafficViolationCardData violationData = TrafficViolationCardData(
      totalViolations: 15,
      handledViolations: 10,
      unhandledViolations: 5,
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
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TrafficViolationCard(data: violationData),
            ),
          ),
          const SizedBox(width: kSpacing / 2),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const ProgressReportCard(data: appealData),
            ),
          ),
        ],
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: ActiveProjectCard(
        onPressedSeeAll: () {
          Get.toNamed(Routes.trafficViolationScreen);
        },
        child: Container(
          height: gridHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              final data = hardcodedTrafficViolationData;
              final violationTypes = data['violationTypes'] as Map<String, int>;
              final timeSeries =
                  data['timeSeries'] as List<Map<String, dynamic>>;
              final startTime =
                  DateTime.now().subtract(const Duration(days: 30));

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
                      child: TrafficViolationBarChart(
                        typeCountMap: violationTypes,
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

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // Reduced for fit
                                  )
                                  ,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: chart,
                          ),
                        ],
                      ),
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
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                      getTooltipColor: (_) =>
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
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
                      getTooltipColor: (_) =>
                          theme.colorScheme.secondaryContainer.withValues(alpha: 0.9),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: showSidebar
          ? Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, kSpacing * 2, 16.0, kSpacing),
              child: _Sidebar(data: controller.getSelectedProject()),
            )
          : null,
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Obx(() {
        final Profile profile = controller.currentProfile;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ProfilTile(
            data: profile,
            onPressedNotification: () => log("Notification clicked"),
            controller: controller,
          ),
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0288D1),
            Color(0xFF4FC3F7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildHeader(
            onPressedMenu: () => controller.openDrawer(),
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 15),
          const Divider(
            height: 1,
            thickness: 1,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    const double horizontalPadding = kSpacing / 2;
    final double availableWidth = screenWidth - 2 * horizontalPadding;
    const double mobileBreakpoint = 600.0;
    final double menuIconWidth = onPressedMenu != null ? 48.0 : 0.0;
    const double iconWidth = 48.0;
    const double iconSpacing = 4.0;
    const double iconsTotalWidth = iconWidth * 2 + iconSpacing;
    final double headerContentAvailableWidth =
        availableWidth - menuIconWidth - iconsTotalWidth;

    return SizedBox(
      height: 50,
      child: Container(
        width: availableWidth,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            if (screenWidth < mobileBreakpoint && onPressedMenu != null)
              IconButton(
                onPressed: () => controller.toggleSidebar(),
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: "菜单",
              ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: headerContentAvailableWidth),
              child: const _Header(),
            ),
            IconButton(
              onPressed: () => controller.toggleChat(),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              tooltip: "AIChat",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => controller.toggleBodyTheme(),
              icon: const Icon(Icons.brightness_6, color: Colors.white),
              tooltip: "切换明暗主题",
            ),
          ],
        ),
      ),
    );
  }
}
