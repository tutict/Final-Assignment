import 'dart:convert';
import 'dart:developer' as develop;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/json_parser.dart';

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
            _dataList = responseData
                .whereType<Map>()
                .map((item) {
                  final parsedTime = JsonParser.asDateTime(item['time']);
                  return {
                    'time': parsedTime,
                    'value1': JsonParser.asDouble(item['value1']) ?? 0,
                    'value2': JsonParser.asDouble(item['value2']) ?? 0,
                  };
                })
                .where((item) => item['time'] != null)
                .toList();
            _startTime = _dataList.isNotEmpty
                ? _dataList.first['time'] as DateTime
                : DateTime.now();
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_dataList.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    final maxX = _dataList
        .map((item) => (item['time'] as DateTime).difference(_startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final maxY1 = _dataList
        .map((item) => (item['value1'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = _dataList
        .map((item) => (item['value2'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxY1 > maxY2 ? maxY1 : maxY2) * 1.2;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY : 500,
              minY: 0,
              barGroups: _buildBarGroups(maxX, scheme),
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
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
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
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
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
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: scheme.outlineVariant.withValues(alpha: 0.2), strokeWidth: 1);
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(color: scheme.outlineVariant.withValues(alpha: 0.2), strokeWidth: 1);
                },
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
          LineChart(
            LineChartData(
              lineBarsData: _buildLineBarsData(scheme),
              minX: 0,
              maxX: maxX > 0 ? maxX : 20,
              minY: 0,
              maxY: maxY > 0 ? maxY : 500,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
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

  List<BarChartGroupData> _buildBarGroups(double maxX, ColorScheme scheme) {
    return _dataList.map((item) {
      final days = (item['time'] as DateTime).difference(_startTime).inDays;
      final value = (item['value1'] as num).toDouble();
      return BarChartGroupData(
        x: days,
        barRods: [
          BarChartRodData(
            toY: value,
            color: scheme.primary.withValues(alpha: 0.3),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    }).toList();
  }

  List<LineChartBarData> _buildLineBarsData(ColorScheme scheme) {
    final line1 = LineChartBarData(
      spots: _dataList.map((item) {
        final days =
            (item['time'] as DateTime).difference(_startTime).inDays.toDouble();
        final value = (item['value1'] as num).toDouble();
        return FlSpot(days, value);
      }).toList(),
      isCurved: false,
      color: scheme.primary,
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
      color: scheme.secondary,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    return [line1, line2];
  }
}
