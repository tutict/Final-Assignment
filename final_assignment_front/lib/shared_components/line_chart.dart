import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

/// 线性图表组件
///
/// LineChart 组件使用 Flutter Chart Plus 库来渲染一个线性图表。该组件通过接收数据列表（dataList）和开始时间（startTime）作为参数，
/// 来展示数据的趋势。图表包含了两个 Y 轴和一个 X 轴，分别用于展示不同的数据系列。
class LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;
  final DateTime startTime;

  const LineChart({
    super.key,
    required this.dataList,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ChartWidget(
        coordinateRender: ChartDimensionsCoordinateRender(
          margin: const EdgeInsets.only(left: 40, top: 5, right: 30, bottom: 30),
          crossHair: const CrossHairStyle(
              adjustHorizontal: true, adjustVertical: true),
          yAxis: [
            YAxis(min: 0, max: 500, drawGrid: true),
            YAxis(
              min: 0,
              max: 400,
              offset: (size) => Offset(size.width - 70, 0),
            ),
          ],
          xAxis: XAxis(
            count: 7,
            max: 20,
            zoom: true,
            drawLine: false,
            formatter: (index) => startTime
                .add(Duration(days: index))
                .toIso8601String()
                .substring(8, 10), // 日期的格式调整为天数
          ),
          charts: [
            Bar(
              color: Colors.yellow,
              data: dataList,
              yAxisPosition: 1,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, startTime),
              value: (item) => (item['value1'] as num).toInt(), // 确保是 int 类型
            ),
            Line(
              data: dataList,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, startTime),
              values: (item) => [
                (item['value1'] as num), // 这里可以保持为 num，因为 Line 图表可能支持浮点数
              ],
            ),
            Line(
              colors: [Colors.green],
              data: dataList,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, startTime),
              values: (item) => [
                (item['value2'] as num),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
