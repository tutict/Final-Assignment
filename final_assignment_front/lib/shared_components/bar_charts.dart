import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

class BarChart extends StatelessWidget {
  const BarChart({super.key});

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
