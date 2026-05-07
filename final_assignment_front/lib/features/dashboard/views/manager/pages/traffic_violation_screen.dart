import 'package:final_assignment_front/features/dashboard/views/shared/components/active_project_card.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/controllers/traffic_violation_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TrafficViolationScreen extends GetView<TrafficViolationController> {
  const TrafficViolationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final violationTypes = Map<String, int>.from(controller.violationTypes);
      final timeSeries = List<Map<String, dynamic>>.from(
        controller.timeSeries,
      );
      final appealReasons = Map<String, int>.from(controller.appealReasons);
      final paymentStatus = Map<String, int>.from(controller.paymentStatus);
      final startTime = controller.startTime.value;

      return DashboardPageTemplate(
        theme: theme,
        title: '交通违法仪表板',
        pageType: DashboardPageType.manager,
        onRefresh: controller.loadDashboardData,
        isLoading: controller.isLoading.value,
        errorMessage: controller.errorMessage.value,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartSection(
              context,
              '违法类型分布',
              violationTypes.isEmpty
                  ? const Center(child: Text('无违法类型数据'))
                  : ActiveProjectCard(
                      title: '违法类型分布',
                      onPressedSeeAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('查看违法类型详情')),
                        );
                      },
                      child: SizedBox(
                        height: 250,
                        child: TrafficViolationBarChart(
                          typeCountMap: violationTypes,
                          startTime: startTime,
                        ),
                      ),
                    ),
            ),
            _buildChartSection(
              context,
              '罚款与扣分趋势',
              timeSeries.isEmpty
                  ? const Center(child: Text('无时间序列数据'))
                  : ActiveProjectCard(
                      title: '罚款与扣分趋势',
                      onPressedSeeAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('查看时间序列详情')),
                        );
                      },
                      child: SizedBox(
                        height: 200,
                        child: _buildLineChart(
                          context,
                          timeSeries,
                          startTime,
                        ),
                      ),
                    ),
            ),
            _buildChartSection(
              context,
              '申诉理由分布',
              appealReasons.isEmpty
                  ? const Center(child: Text('无申诉理由数据'))
                  : ActiveProjectCard(
                      title: '申诉理由分布',
                      onPressedSeeAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('查看申诉理由详情')),
                        );
                      },
                      child: SizedBox(
                        height: 250,
                        child: TrafficViolationPieChart(
                          data: appealReasons,
                        ),
                      ),
                    ),
            ),
            _buildChartSection(
              context,
              '罚款支付状态',
              paymentStatus.isEmpty
                  ? const Center(child: Text('无支付状态数据'))
                  : ActiveProjectCard(
                      title: '罚款支付状态',
                      onPressedSeeAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('查看支付状态详情')),
                        );
                      },
                      child: SizedBox(
                        height: 250,
                        child: TrafficViolationPieChart(
                          data: paymentStatus,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChartSection(BuildContext context, String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: chart,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    List<Map<String, dynamic>> timeSeries,
    DateTime startTime,
  ) {
    if (timeSeries.isEmpty) {
      return const Center(child: Text('无时间序列数据可用'));
    }

    final theme = Theme.of(context);
    final dataList = timeSeries
        .map((item) {
          final rawTime = item['time'];
          final parsedTime = rawTime is DateTime
              ? rawTime
              : DateTime.tryParse(rawTime?.toString() ?? '');
          if (parsedTime == null) return null;
          return {
            'time': parsedTime,
            'value1': (item['value1'] as num?)?.toDouble() ?? 0,
            'value2': (item['value2'] as num?)?.toDouble() ?? 0,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (dataList.isEmpty) {
      return const Center(child: Text('无时间序列数据可用'));
    }

    final maxX = dataList
        .map((item) => (item['time'] as DateTime).difference(startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY1 = dataList
        .map((item) => item['value1'] as double)
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = dataList
        .map((item) => item['value2'] as double)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxY1 > maxY2 ? maxY1 : maxY2) * 1.2;
    final chartMaxY = maxY > 0 ? maxY : 500.0;

    return Stack(
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMaxY,
            minY: 0,
            barGroups: dataList.asMap().entries.map((entry) {
              final item = entry.value;
              final days =
                  (item['time'] as DateTime).difference(startTime).inDays;
              final value = item['value1'] as double;
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
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
                  reservedSize: 48,
                  interval: chartMaxY / 5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: maxX > 7 ? maxX / 7 : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final date = startTime.add(Duration(days: index));
                    return Text(
                      DateFormat('MM-dd').format(date),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
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
              horizontalInterval: chartMaxY / 5,
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
                      fontSize: 14,
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
                  return FlSpot(days, item['value1'] as double);
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
                  return FlSpot(days, item['value2'] as double);
                }).toList(),
                isCurved: true,
                color: theme.colorScheme.secondary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
            ],
            minX: 0,
            maxX: maxX > 0 ? maxX : 30,
            minY: 0,
            maxY: chartMaxY,
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
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final date = startTime.add(Duration(days: spot.x.toInt()));
                  final label = spot.barIndex == 0 ? '罚款' : '扣分';
                  return LineTooltipItem(
                    '${DateFormat('yyyy-MM-dd').format(date)}\n$label: ${spot.y.toInt()}',
                    TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Pie chart wrapper
class TrafficViolationPieChartCard extends StatelessWidget {
  final Map<String, int> data;
  final String title;

  const TrafficViolationPieChartCard({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ActiveProjectCard(
      title: title,
      onPressedSeeAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("查看详情：$title")),
        );
      },
      child: SizedBox(
        height: 250,
        child: TrafficViolationPieChart(data: data),
      ),
    );
  }
}

// Pie chart with dynamic data
class TrafficViolationPieChart extends StatelessWidget {
  final Map<String, int> data;

  const TrafficViolationPieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('无数据可用'));
    }

    final theme = Theme.of(context);
    final dataList = data.entries.toList();
    final totalCount = data.values.reduce((a, b) => a + b);

    final colors = List<Color>.generate(
      dataList.length,
      (index) => [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
        theme.colorScheme.error,
        theme.colorScheme.primaryContainer,
      ][index % 5],
    );

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections:
                  _buildPieChartSections(dataList, colors, totalCount, theme),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '总数',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  totalCount.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, int>> dataList,
    List<Color> colors,
    int totalCount,
    ThemeData theme,
  ) {
    return List.generate(dataList.length, (index) {
      final entry = dataList[index];
      final value = entry.value.toDouble();
      final percentage = (value / totalCount * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: value,
        color: colors[index],
        radius: 100,
        title: '$percentage%',
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
        badgeWidget: _buildBadgeWidget(entry.key, colors[index], theme),
        badgePositionPercentageOffset: 1.2,
      );
    });
  }

  Widget _buildBadgeWidget(String type, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Bar chart with dynamic data
class TrafficViolationBarChart extends StatelessWidget {
  final Map<String, int> typeCountMap;
  final DateTime startTime;

  const TrafficViolationBarChart({
    super.key,
    required this.typeCountMap,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    if (typeCountMap.isEmpty) {
      return const Center(child: Text('无违法数据可用'));
    }

    final theme = Theme.of(context);
    final dataList = typeCountMap.entries.toList();
    final maxY = dataList
            .map((entry) => entry.value.toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipColor: (_) =>
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dataList[groupIndex].key}\n${rod.toY.toInt()} 次',
                  TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dataList.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dataList[index].key,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
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
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
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
          barGroups: dataList.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value.value.toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.2),
                  ),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }
}
