import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

/// 计算两个日期之间的天数差值
/// 
/// 参数:
/// - dateTime: 要计算的日期
/// - startTime: 起始日期
/// 
/// 返回:
/// - 两个日期之间的天数差值
double parserDateTimeToDayValue(DateTime dateTime, DateTime startTime) {
  return dateTime.difference(startTime).inDays.toDouble();
}

/// BarChart 组件用于展示条形图。
/// 它继承自StatelessWidget，用于在Flutter应用中展示静态的条形图表。
class BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;
  final DateTime startTime;

  const BarChart({
    super.key,
    required this.dataList,
    required this.startTime,
  });

  /// 构建并返回一个Widget树，用于展示条形图。
  ///
  /// 参数:
  /// - context: BuildContext对象，用于获取有关构建上下文的信息。
  ///
  /// 返回:
  /// - 一个SizedBox widget，包含一个ChartWidget，用于实际展示条形图。
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 300,
        child: ChartWidget(
          coordinateRender: ChartDimensionsCoordinateRender(
            yAxis: [YAxis(min: 0, max: 500)],
            margin:
                const EdgeInsets.only(left: 40, top: 0, right: 0, bottom: 30),
            xAxis: XAxis(
              count: 7,
              max: 30,
              zoom: true,
              formatter: (index) {
                // 确保startTime存在，使用format来格式化日期
                return startTime
                    .add(Duration(days: index.toInt()))
                    .toIso8601String()
                    .substring(8, 10); // 只获取日期中的日部分
              },
            ),
            charts: [
              StackBar(
                data: dataList,
                position: (item) {
                  return parserDateTimeToDayValue(
                      item['time'] as DateTime, startTime);
                },
                direction: Axis.horizontal,
                itemWidth: 10,
                highlightColor: Colors.yellow,
                values: (item) => [
                  double.parse(item['value1'].toString()),
                  double.parse(item['value2'].toString()),
                  double.parse(item['value3'].toString()),
                ],
              ),
            ],
          ),
        ));
  }
}
