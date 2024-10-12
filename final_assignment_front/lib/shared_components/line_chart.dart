import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

class LineChart extends StatelessWidget {
  const LineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ChartWidget(
        coordinateRender: ChartDimensionsCoordinateRender(
          margin:
              const EdgeInsets.only(left: 40, top: 5, right: 30, bottom: 30),
          crossHair: const CrossHairStyle(
              adjustHorizontal: true, adjustVertical: true),
          tooltipFormatter: (list) => TextSpan(
            text: list.map((e) => e['value1']).toString(),
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
          yAxis: [
            YAxis(min: 0, max: 500, drawGrid: true),
            YAxis(
                min: 0, max: 400, offset: (size) => Offset(size.width - 70, 0)),
          ],
          xAxis: XAxis(
            count: 7,
            max: 20,
            zoom: true,
            drawLine: false,
            formatter: (index) => startTime
                .add(Duration(days: index))
                .toStringWithFormat(format: 'dd'),
          ),
          charts: [
            Bar(
              color: Colors.yellow,
              data: dataList,
              yAxisPosition: 1,
              position: (item) =>
                  parserDateTimeToDayValue(item['time'] as DateTime, startTime),
              value: (item) => item['value1'],
            ),
            Line(
              data: dataList,
              position: (item) =>
                  parserDateTimeToDayValue(item['time'] as DateTime, startTime),
              values: (item) => [
                item['value1'] as num,
              ],
            ),
            Line(
              colors: [Colors.green],
              data: dataList,
              position: (item) =>
                  parserDateTimeToDayValue(item['time'] as DateTime, startTime),
              values: (item) => [
                item['value2'] as num,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
