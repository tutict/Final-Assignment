import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';

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

    // 转换为数据列表
    final dataList = typeCountMap.entries.map((entry) {
      return {
        'time': startTime, // 固定起始时间，条形图按类型分组
        'value1': entry.value.toDouble(), // 数量作为值
        'value2': 0.0, // 仅使用一个值，剩余设为 0
        'value3': 0.0,
      };
    }).toList();

    // Handle case where dataList is empty
    if (dataList.isEmpty) {
      return const Center(
        child: Text('No offense data available'),
      );
    }

    return SizedBox(
      height: 300,
      child: ChartWidget(
        coordinateRender: ChartDimensionsCoordinateRender(
          yAxis: [
            YAxis(
              min: 0,
              max: typeCountMap.values.isNotEmpty
                  ? (typeCountMap.values.reduce((a, b) => a > b ? a : b) * 1.2)
                  .toDouble()
                  : 100.0, // Default max if empty
            )
          ],
          margin: const EdgeInsets.only(left: 40, top: 0, right: 0, bottom: 30),
          xAxis: XAxis(
            count: typeCountMap.length,
            max: typeCountMap.length.toDouble(),
            zoom: false, // 禁用缩放
            formatter: (index) {
              return typeCountMap.keys.elementAt(index.toInt());
            },
          ),
          charts: [
            StackBar(
              data: dataList,
              position: (item) => indexOfType(
                  item['time'] as DateTime, typeCountMap.keys.toList()),
              direction: Axis.horizontal,
              itemWidth: 20,
              highlightColor: Colors.yellow,
              values: (item) => [item['value1']],
            ),
          ],
        ),
      ),
    );
  }

  double indexOfType(DateTime time, List<String> types) {
    return types
        .indexOf(typeCountMap.keys.firstWhere((k) => true))
        .toDouble(); // 简化为顺序索引
  }
}