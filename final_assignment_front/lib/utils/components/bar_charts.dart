import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 条形图组件，用于展示交通违法类型的分布（theme-aware）。
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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final axisColor = scheme.onSurfaceVariant;
    final gridColor =
        scheme.outlineVariant.withValues(alpha: dark ? 0.16 : 0.4);

    // Handle empty or null typeCountMap
    if (typeCountMap.isEmpty) {
      return Center(
        child: Text(
          '暂无违法数据',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
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
          barGroups: _buildBarGroups(types, scheme),
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
                    style: TextStyle(color: axisColor, fontSize: 12),
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: axisColor, fontSize: 12),
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
          // 网格线设置：去掉重竖线，横线更浅更细
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: gridColor,
              strokeWidth: 1,
            ),
          ),
          // 边框设置
          borderData: FlBorderData(show: false),
          // 触摸交互设置：主题色 tooltip
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  dark ? const Color(0xFF1E2733) : const Color(0xFF17304d),
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${types[groupIndex]}\n${rod.toY.toInt()} 起',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 构建条形图组数据（主色渐变 + 浅色背景槽）
  List<BarChartGroupData> _buildBarGroups(
      List<String> types, ColorScheme scheme) {
    return List.generate(types.length, (index) {
      final count = typeCountMap[types[index]]?.toDouble() ?? 0.0;
      final maxRaw = typeCountMap.values.isNotEmpty
          ? typeCountMap.values.reduce((a, b) => a > b ? a : b)
          : 100.0;
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scheme.primary, scheme.primary.withValues(alpha: 0.55)],
      );
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            gradient: fillGradient,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (maxRaw * 1.2).toDouble(),
              color: scheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });
  }
}