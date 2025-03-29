import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrafficViolationPieChart extends StatelessWidget {
  final Map<String, int> typeCountMap;

  const TrafficViolationPieChart({super.key, required this.typeCountMap});

  @override
  Widget build(BuildContext context) {
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
              sections: _buildPieChartSections(dataList, colors, totalCount),
              sectionsSpace: 2, // 饼图各部分之间的间距
              centerSpaceRadius: 40, // 中心空白区域的半径
              borderData: FlBorderData(show: false),
            ),
          ),
          // 在中心显示总计
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  totalCount.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
      int totalCount) {
    return List.generate(dataList.length, (index) {
      final entry = dataList[index];
      final value = entry.value.toDouble();
      final percentage = (value / totalCount * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: value,
        // 饼图部分的值
        color: colors[index],
        // 颜色
        radius: 100,
        // 饼图部分的半径
        title: '$percentage%',
        // 显示百分比
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _buildBadgeWidget(entry.key, colors[index]),
        // 自定义标签
        badgePositionPercentageOffset: 1.2, // 标签位置（相对于中心的偏移）
      );
    });
  }

  // 构建标签小部件
  Widget _buildBadgeWidget(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
