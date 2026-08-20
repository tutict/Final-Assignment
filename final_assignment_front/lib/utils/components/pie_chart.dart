import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OffensePieChart extends StatelessWidget {
  final Map<String, int> typeCountMap;

  const OffensePieChart({super.key, required this.typeCountMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (typeCountMap.isEmpty) {
      return const Center(
        child: Text('No offense data available'),
      );
    }

    // 转换为饼图数据
    final dataList = typeCountMap.entries.toList();
    final totalCount = typeCountMap.values.reduce((a, b) => a + b);

    // 生成颜色列表
    final colors = List<Color>.generate(
      dataList.length,
      (index) => Colors.primaries[index % Colors.primaries.length][500]!,
    );

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: _buildPieChartSections(dataList, colors, totalCount, scheme),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
            ),
          ),
          // 在中心显示总计
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  totalCount.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
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

  // 构建饼图数据
  List<PieChartSectionData> _buildPieChartSections(
      List<MapEntry<String, int>> dataList,
      List<Color> colors,
      int totalCount,
      ColorScheme scheme) {
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
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0,
        ),
        badgeWidget: _buildBadgeWidget(entry.key, colors[index]),
        badgePositionPercentageOffset: 1.2,
      );
    });
  }

  // 构建标签小部件
  Widget _buildBadgeWidget(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
