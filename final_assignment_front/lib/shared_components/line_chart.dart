import 'dart:convert';
import 'dart:developer' as develop;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LineChart extends StatefulWidget {
  const LineChart(
    LineChartData lineChartData, {
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
      develop.log('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果数据为空，显示提示
    if (_dataList.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    // 计算 X 轴最大值（天数）
    final maxX = _dataList
        .map((item) => (item['time'] as DateTime).difference(_startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // 计算 Y 轴最大值
    final maxY1 = _dataList
        .map((item) => (item['value1'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = _dataList
        .map((item) => (item['value2'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxY1 > maxY2 ? maxY1 : maxY2) * 1.2; // 增加 20% 余量

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // 柱状图（BarChart）
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY : 500,
              minY: 0,
              barGroups: _buildBarGroups(maxX),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: maxX > 7 ? maxX / 7 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final date = _startTime.add(Duration(days: index));
                      return Text(
                        date.toIso8601String().substring(8, 10),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                horizontalInterval: maxY / 5,
                verticalInterval: maxX > 7 ? maxX / 7 : 1,
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = _startTime.add(Duration(days: group.x));
                    return BarTooltipItem(
                      '${date.toIso8601String().substring(0, 10)}\n${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
          // 折线图（LineChart）
          LineChart(
            LineChartData(
              lineBarsData: _buildLineBarsData(),
              minX: 0,
              maxX: maxX > 0 ? maxX : 20,
              minY: 0,
              maxY: maxY > 0 ? maxY : 500,
              titlesData: const FlTitlesData(show: false),
              // 避免重复显示标题
              gridData: const FlGridData(show: false),
              // 避免重复显示网格线
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date =
                          _startTime.add(Duration(days: spot.x.toInt()));
                      return LineTooltipItem(
                        '${date.toIso8601String().substring(0, 10)}\n${spot.y.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建柱状图数据
  List<BarChartGroupData> _buildBarGroups(double maxX) {
    return _dataList.map((item) {
      final days = (item['time'] as DateTime).difference(_startTime).inDays;
      final value = (item['value1'] as num).toDouble();
      return BarChartGroupData(
        x: days,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.yellow.withOpacity(0.5), // 半透明以避免遮挡折线
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    }).toList();
  }

  // 构建折线图数据
  List<LineChartBarData> _buildLineBarsData() {
    final line1 = LineChartBarData(
      spots: _dataList.map((item) {
        final days =
            (item['time'] as DateTime).difference(_startTime).inDays.toDouble();
        final value = (item['value1'] as num).toDouble();
        return FlSpot(days, value);
      }).toList(),
      isCurved: false,
      color: Colors.yellow,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    final line2 = LineChartBarData(
      spots: _dataList.map((item) {
        final days =
            (item['time'] as DateTime).difference(_startTime).inDays.toDouble();
        final value = (item['value2'] as num).toDouble();
        return FlSpot(days, value);
      }).toList(),
      isCurved: false,
      color: Colors.green,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    return [line1, line2];
  }
}
