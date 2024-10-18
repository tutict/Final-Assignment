import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

/// BarChart 组件用于展示条形图。
/// 它继承自StatelessWidget，用于在Flutter应用中展示静态的条形图表。
class BarChart extends StatelessWidget {
  const BarChart({super.key});

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
                return startTime
                    .add(Duration(days: index))
                    .toStringWithFormat(format: 'dd');
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
