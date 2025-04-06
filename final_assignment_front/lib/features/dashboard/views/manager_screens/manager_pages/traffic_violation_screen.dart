import 'package:final_assignment_front/features/api/traffic_violation_controller_api.dart';
import 'package:final_assignment_front/shared_components/bar_charts.dart';
import 'package:final_assignment_front/shared_components/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class TrafficViolationScreen extends StatefulWidget {
  const TrafficViolationScreen({super.key});

  @override
  State<TrafficViolationScreen> createState() => _TrafficViolationScreenState();
}

class _TrafficViolationScreenState extends State<TrafficViolationScreen> {
  final TrafficViolationControllerApi _api = TrafficViolationControllerApi();
  Map<String, int>? _violationTypes;
  List<Map<String, dynamic>>? _timeSeries;
  Map<String, int>? _appealReasons;
  Map<String, int>? _paymentStatus;
  String? _error;
  final DateTime _startTime = DateTime.now().subtract(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await _api.initializeWithJwt();
      setState(() => _error = null);

      final startTimeStr =
          DateFormat('yyyy-MM-ddTHH:mm:ssZ').format(_startTime);
      _violationTypes = await _api.apiTrafficViolationsViolationTypesGet(
          startTime: startTimeStr);
      _timeSeries =
          await _api.apiTrafficViolationsTimeSeriesGet(startTime: startTimeStr);
      _appealReasons = await _api.apiTrafficViolationsAppealReasonsGet(
          startTime: startTimeStr);
      _paymentStatus = await _api.apiTrafficViolationsFinePaymentStatusGet(
          startTime: startTimeStr);

      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Violation Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Text('Error: $_error',
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 16),
            ],
            _buildChartSection(
              'Violation Types (Bar Chart)',
              TrafficViolationBarChart(
                  typeCountMap: _violationTypes ?? {}, startTime: _startTime),
            ),
            _buildChartSection(
              'Time Series (Fines & Points)',
              _buildLineChart(),
            ),
            _buildChartSection(
              'Appeal Reasons (Pie Chart)',
              TrafficViolationPieChart(typeCountMap: _appealReasons ?? {}),
            ),
            _buildChartSection(
              'Payment Status (Pie Chart)',
              TrafficViolationPieChart(typeCountMap: _paymentStatus ?? {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300, // Consistent height for all charts
          child: chart,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_timeSeries == null || _timeSeries!.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No time series data available')),
      );
    }

    // Convert _timeSeries to match LineChart expectations
    final dataList = _timeSeries!
        .map((item) => {
              'time': DateTime.parse(item['time']),
              'value1': item['value1'] as num,
              'value2': item['value2'] as num,
            })
        .toList();

    final maxX = dataList
        .map((item) => (item['time'] as DateTime).difference(_startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final maxY1 = dataList
        .map((item) => (item['value1'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = dataList
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
              barGroups: dataList.map((item) {
                final days =
                    (item['time'] as DateTime).difference(_startTime).inDays;
                final value = (item['value1'] as num).toDouble();
                return BarChartGroupData(
                  x: days,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: Colors.yellow.withOpacity(0.5),
                      width: 8,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
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
                        DateFormat('dd').format(date),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
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
                      '${DateFormat('yyyy-MM-dd').format(date)}\nFines: ${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
          LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: dataList.map((item) {
                    final days = (item['time'] as DateTime)
                        .difference(_startTime)
                        .inDays
                        .toDouble();
                    return FlSpot(days, (item['value1'] as num).toDouble());
                  }).toList(),
                  isCurved: false,
                  color: Colors.yellow,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: dataList.map((item) {
                    final days = (item['time'] as DateTime)
                        .difference(_startTime)
                        .inDays
                        .toDouble();
                    return FlSpot(days, (item['value2'] as num).toDouble());
                  }).toList(),
                  isCurved: false,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    final date = _startTime.add(Duration(days: spot.x.toInt()));
                    final label = spot.barIndex == 0 ? 'Fines' : 'Points';
                    return LineTooltipItem(
                      '${DateFormat('yyyy-MM-dd').format(date)}\n$label: ${spot.y.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
