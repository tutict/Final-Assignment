library manager_dashboard;

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/traffic_violation_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/dashboard/views/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/components/profile_tile.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/shared_components/TrafficViolationCard.dart';
import 'package:final_assignment_front/shared_components/bar_charts.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/pie_chart.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/mixins/app_mixins.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// binding
part '../../bindings/manager_dashboard_binding.dart';

// controller
part '../../controllers/manager_dashboard_controller.dart';

// components
part '../components/active_project_card.dart';

part '../components/header.dart';

part '../components/overview_header.dart';

part '../components/recent_messages.dart';

part '../components/sidebar.dart';

part '../components/team_member.dart';

class DashboardScreen extends GetView<DashboardController>
    with NavigationMixin {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      child: _Sidebar(data: controller.getSelectedProject()),
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
                        color: Theme.of(context).cardColor,
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                        boxShadow: kBoxShadows,
                      ),
                      child: _Sidebar(data: controller.getSelectedProject()),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: SingleChildScrollView(
                          child: _buildLayout(context),
                        ),
                      ),
                    ),
                    Obx(
                      () => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: controller.isChatExpanded.value
                            ? (screenWidth * 0.3 > 150
                                ? screenWidth * 0.3
                                : 150)
                            : 0,
                        // AiChat 动态宽度
                        height: screenHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
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
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.3, // 限制最大宽度
        minWidth: 150, // 确保最小宽度
        maxHeight: MediaQuery.of(context).size.height, // 限制最大高度为屏幕高度
      ),
      child: const AiChat(),
    );
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSpacing, vertical: kSpacing / 2),
        // Reduced vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed or reduced SizedBox to minimize top space
            SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 1.0 : 1.5)),
            // Adjusted multiplier
            const Divider(),
            Obx(() {
              final pageContent = controller.selectedPage.value;
              if (pageContent != null) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: kBoxShadows,
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
                      crossAxisCount: isDesktop ? 4 : 2,
                      childAspectRatio: isDesktop ? 1.1 : 1.2,
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
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

    return const Padding(
      padding:
          EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing / 2),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: TrafficViolationCard(data: violationData),
          ),
          SizedBox(width: kSpacing / 2),
          Expanded(
            child: ProgressReportCard(data: appealData),
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
          ListProfilImage(
            maxImages: 6,
            images: controller.getMember(),
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
    double gridHeight;
    if (crossAxisCount == 2) {
      gridHeight = MediaQuery.of(context).size.height * 1.44;
    } else if (crossAxisCount == 3) {
      gridHeight = MediaQuery.of(context).size.height * 0.94;
    } else {
      gridHeight = MediaQuery.of(context).size.height * 0.78;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ActiveProjectCard(
        onPressedSeeAll: () => log("查看所有项目"),
        child: SizedBox(
          height: gridHeight,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchTrafficViolationData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                log('Error in FutureBuilder: ${snapshot.error}');
                String errorMessage = 'Failed to load traffic violation data';
                if (snapshot.error is ApiException) {
                  final apiError = snapshot.error as ApiException;
                  errorMessage =
                      'API Error ${apiError.code}: ${apiError.message}';
                  try {
                    final errorJson = jsonDecode(apiError.message);
                    if (errorJson['message'] != null) {
                      errorMessage += ' - ${errorJson['message']}';
                    }
                  } catch (_) {
                    // If message isn't JSON or lacks detail, use raw message
                  }
                }
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => (() {}), // Retry fetch
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data available'));
              } else {
                final data = snapshot.data!;
                final violationTypes =
                    data['violationTypes'] as Map<String, int>;
                final timeSeries =
                    data['timeSeries'] as List<Map<String, dynamic>>;
                final paymentStatus = data['paymentStatus'] as Map<String, int>;
                final startTime =
                    DateTime.now().subtract(const Duration(days: 30));

                return GridView.builder(
                  itemCount: crossAxisCount >= 3
                      ? 3
                      : crossAxisCount >= 2
                          ? 2
                          : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: kSpacing,
                    mainAxisSpacing: kSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return TrafficViolationBarChart(
                        typeCountMap: violationTypes,
                        startTime: startTime,
                      );
                    } else if (index == 1) {
                      return _buildTimeSeriesChart(timeSeries, startTime);
                    } else {
                      return TrafficViolationPieChart(
                        typeCountMap: paymentStatus,
                      );
                    }
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchTrafficViolationData() async {
    final api = TrafficViolationControllerApi();
    await api.initializeWithJwt();
    final startTimeStr = DateFormat('yyyy-MM-ddTHH:mm:ssZ')
        .format(DateTime.now().subtract(const Duration(days: 30)));

    try {
      log('Fetching traffic violation data with startTime: $startTimeStr');
      final violationTypes = await api.apiTrafficViolationsViolationTypesGet(
          startTime: startTimeStr);
      final timeSeries =
          await api.apiTrafficViolationsTimeSeriesGet(startTime: startTimeStr);
      final paymentStatus = await api.apiTrafficViolationsFinePaymentStatusGet(
          startTime: startTimeStr);

      return {
        'violationTypes': violationTypes,
        'timeSeries': timeSeries,
        'paymentStatus': paymentStatus,
      };
    } catch (e) {
      log('Error fetching traffic violation data: $e');
      rethrow; // Let FutureBuilder handle the error
    }
  }

// Time series chart implementation remains unchanged (as previously provided)
  Widget _buildTimeSeriesChart(
      List<Map<String, dynamic>> timeSeries, DateTime startTime) {
    if (timeSeries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No time series data available')),
      );
    }

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

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY : 500,
              minY: 0,
              barGroups: dataList.map((item) {
                final days =
                    (item['time'] as DateTime).difference(startTime).inDays;
                final value = (item['value1'] as num).toDouble();
                return BarChartGroupData(
                  x: days,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: Colors.yellow.withOpacity(0.5),
                      width: 8,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: maxX > 7 ? maxX / 7 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final date = startTime.add(Duration(days: index));
                      return Text(
                        DateFormat('dd').format(date),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 5,
                verticalInterval: maxX > 7 ? maxX / 7 : 1,
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = startTime.add(Duration(days: group.x));
                    return BarTooltipItem(
                      '${DateFormat('yyyy-MM-dd').format(date)}\nFines: ${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white),
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
                  spots: dataList.map((item) {
                    final days = (item['time'] as DateTime)
                        .difference(startTime)
                        .inDays
                        .toDouble();
                    return FlSpot(days, (item['value1'] as num).toDouble());
                  }).toList(),
                  isCurved: false,
                  color: Colors.yellow,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: dataList.map((item) {
                    final days = (item['time'] as DateTime)
                        .difference(startTime)
                        .inDays
                        .toDouble();
                    return FlSpot(days, (item['value2'] as num).toDouble());
                  }).toList(),
                  isCurved: false,
                  color: Colors.green,
                  barWidth: 2,
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    final date = startTime.add(Duration(days: spot.x.toInt()));
                    final label = spot.barIndex == 0 ? 'Fines' : 'Points';
                    return LineTooltipItem(
                      '${DateFormat('yyyy-MM-dd').format(date)}\n$label: ${spot.y.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final bool isDesktop = ResponsiveBuilder.isDesktop(context);
    final bool showSidebar = isDesktop || controller.isSidebarOpen.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: kBoxShadows,
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
        final Profile profile = controller.currentProfile; // 使用 Profile 类型
        return ProfilTile(
          data: profile,
          onPressedNotification: () => log("Notification clicked"),
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    return Container(
      color: Colors.blueAccent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildHeader(
            onPressedMenu: () => controller.openDrawer(),
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, thickness: 1),
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
                icon: const Icon(Icons.menu),
                tooltip: "菜单",
              ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: headerContentAvailableWidth),
              child: const _Header(),
            ),
            IconButton(
              onPressed: () => controller.toggleChat(),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "AIChat",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => controller.toggleBodyTheme(),
              icon: const Icon(Icons.brightness_6),
              tooltip: "切换明暗主题",
            ),
          ],
        ),
      ),
    );
  }
}
