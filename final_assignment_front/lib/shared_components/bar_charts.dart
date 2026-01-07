import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 条形图组件，用于展示交通违法类型的分布
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
    // Handle empty or null typeCountMap
    if (typeCountMap.isEmpty) {
      return const Center(
        child: Text('No offense data available'),
      );
    }

    // 获取类型列表和最大值
    final List<String> types = typeCountMap.keys.toList();
    final double maxY = typeCountMap.values.isNotEmpty
        ? (typeCountMap.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
        : 100.0; // 默认最大值

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          // 条形图对齐方式
          alignment: BarChartAlignment.spaceAround,
          // Y 轴范围
          maxY: maxY,
          minY: 0,
          // 条形图组数据
          barGroups: _buildBarGroups(types),
          // 标题设置（X 轴和 Y 轴标签）
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
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
                      meta: meta, // 传递 meta 参数
                      space: 8.0, // 可选：设置标题与图表的间距
                      child: Text(
                        types[index],
                        style: const TextStyle(
                          color: Colors.black,
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
          // 网格线设置
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
          ),
          // 边框设置
          borderData: FlBorderData(show: false),
          // 触摸交互设置
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

  // 构建条形图组数据
  List<BarChartGroupData> _buildBarGroups(List<String> types) {
    return List.generate(types.length, (index) {
      final count = typeCountMap[types[index]]?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: typeCountMap.values.isNotEmpty
                  ? (typeCountMap.values.reduce((a, b) => a > b ? a : b) * 1.2)
                      .toDouble()
                  : 100.0,
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ],
      );
    });
  }
}
