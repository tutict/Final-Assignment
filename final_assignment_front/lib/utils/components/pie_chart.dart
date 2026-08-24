import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OffensePieChart extends StatelessWidget {
  final Map<String, int> typeCountMap;

  const OffensePieChart({super.key, required this.typeCountMap});

  /// 一组互不冲突、在亮/暗背景下都协调的分类色。
  static const _palette = <Color>[
    Color(0xFF3B82F6), // 蓝
    Color(0xFF10B981), // 绿
    Color(0xFFF59E0B), // 琥珀
    Color(0xFFEF4444), // 红
    Color(0xFF8B5CF6), // 紫
    Color(0xFF06B6D4), // 青
    Color(0xFFF97316), // 橙
    Color(0xFFEC4899), // 粉
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    if (typeCountMap.isEmpty) {
      return Center(
        child: Text(
          '暂无违章数据',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    // 转换为饼图数据
    final dataList = typeCountMap.entries.toList();
    final totalCount = typeCountMap.values.reduce((a, b) => a + b);

    // 生成颜色列表：分类色循环取用
    final colors = List<Color>.generate(
      dataList.length,
      (index) => _palette[index % _palette.length],
    );

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: _buildPieChartSections(dataList, colors, totalCount),
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              borderData: FlBorderData(show: false),
            ),
          ),
          // 在中心显示总计
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '违章总数',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  totalCount.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
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
          fontSize: 13,
          fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}