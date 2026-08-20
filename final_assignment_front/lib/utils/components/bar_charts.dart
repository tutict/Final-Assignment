import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 条形图组件，用于展示交通违法类型的分布
class OffenseBarChart extends StatelessWidget {
  final Map<String, int> typeCountMap;
  final DateTime startTime;

  const OffenseBarChart({
    super.key,
    required this.typeCountMap,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Handle empty or null typeCountMap
    if (typeCountMap.isEmpty) {
      return Center(
        child: Text('No offense data available', style: TextStyle(color: scheme.onSurface)),
      );
    }

    // 获取类型列表和最大值
    final List<String> types = typeCountMap.keys.toList();
    final double maxY = typeCountMap.values.isNotEmpty
        ? (typeCountMap.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
        : 100.0;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barGroups: _buildBarGroups(types, scheme),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < types.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8.0,
                      child: Text(
                        types[index],
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${types[groupIndex]}: ${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<String> types, ColorScheme scheme) {
    return List.generate(types.length, (index) {
      final count = typeCountMap[types[index]]?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            color: scheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: typeCountMap.values.isNotEmpty
                  ? (typeCountMap.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
                  : 100.0,
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ],
      );
    });
  }
}
