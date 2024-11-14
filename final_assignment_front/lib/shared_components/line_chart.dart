import 'dart:convert';
import 'dart:developer' as develop;

import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';
import 'package:http/http.dart' as http;

class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
  });

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  List<Map<String, dynamic>> _dataList = [];
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    try {
      final response = await http
          .get(Uri.parse('\${AppConfig.baseUrl}/eventbus/chart-data'));
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> responseData = jsonDecode(response.body);
          if (responseData.isNotEmpty) {
            _dataList = responseData.map((item) {
              return {
                'time': DateTime.parse(item['time']),
                'value1': item['value1'],
                'value2': item['value2'],
              };
            }).toList();
            _startTime = DateTime.parse(responseData.first['time']);
          }
        });
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      develop.log('Error: \$e');
    }
  }

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
            formatter: (index) => _startTime
                .add(Duration(days: index.toInt()))
                .toIso8601String()
                .substring(8, 10),
          ),
          charts: [
            Bar(
              color: Colors.yellow,
              data: _dataList,
              yAxisPosition: 1,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, _startTime),
              value: (item) => (item['value1'] as num).toDouble(),
            ),
            Line(
              data: _dataList,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, _startTime),
              values: (item) => [
                (item['value1'] as num).toDouble(),
              ],
            ),
            Line(
              colors: [Colors.green],
              data: _dataList,
              position: (item) => parserDateTimeToDayValue(
                  item['time'] as DateTime, _startTime),
              values: (item) => [
                (item['value2'] as num).toDouble(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int parserDateTimeToDayValue(DateTime dateTime, DateTime startTime) {
  return dateTime.difference(startTime).inDays;
}
