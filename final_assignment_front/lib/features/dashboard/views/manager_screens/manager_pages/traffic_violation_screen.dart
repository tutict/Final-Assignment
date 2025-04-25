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
  bool _isLoading = false;
  final DateTime _startTime = DateTime.now().subtract(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _api.initializeWithJwt();
      final startTimeStr =
          DateFormat('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'').format(_startTime);

      final violationTypes = await _api.apiTrafficViolationsViolationTypesGet(
          startTime: startTimeStr);
      final timeSeries =
          await _api.apiTrafficViolationsTimeSeriesGet(startTime: startTimeStr);
      final appealReasons = await _api.apiTrafficViolationsAppealReasonsGet(
          startTime: startTimeStr);
      final paymentStatus = await _api.apiTrafficViolationsFinePaymentStatusGet(
          startTime: startTimeStr);

      setState(() {
        _violationTypes = violationTypes;
        _timeSeries = timeSeries;
        _appealReasons = appealReasons;
        _paymentStatus = paymentStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Violation Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else ...[
                _buildChartSection(
                  'Violation Types',
                  _violationTypes == null || _violationTypes!.isEmpty
                      ? const Center(child: Text('No violation types data'))
                      : TrafficViolationBarChart(
                          typeCountMap: _violationTypes!,
                          startTime: _startTime,
                        ),
                ),
                _buildChartSection(
                  'Time Series (Fines & Points)',
                  _buildLineChart(),
                ),
                _buildChartSection(
                  'Appeal Reasons',
                  _appealReasons == null || _appealReasons!.isEmpty
                      ? const Center(child: Text('No appeal reasons data'))
                      : TrafficViolationPieChart(typeCountMap: _appealReasons!),
                ),
                _buildChartSection(
                  'Payment Status',
                  _paymentStatus == null || _paymentStatus!.isEmpty
                      ? const Center(child: Text('No payment status data'))
                      : TrafficViolationPieChart(typeCountMap: _paymentStatus!),
                ),
              ],
            ],
          ),
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
          height: 450, // Increased chart height for larger display
          width: double.infinity, // Ensure charts take full width
          child: chart,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_timeSeries == null || _timeSeries!.isEmpty) {
      return const Center(child: Text('No time series data available'));
    }

    // Convert _timeSeries to match LineChart expectations
    final dataList = _timeSeries!
        .map((item) => {
              'time': DateTime.parse(item['time'] as String),
              'value1': (item['value1'] as num).toDouble(),
              'value2': (item['value2'] as num).toDouble(),
            })
        .toList();

    // Calculate max values for scaling
    final maxX = dataList
        .map((item) => (item['time'] as DateTime).difference(_startTime).inDays)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY1 = dataList
        .map((item) => item['value1'] as double)
        .reduce((a, b) => a > b ? a : b);
    final maxY2 = dataList
        .map((item) => item['value2'] as double)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxY1 > maxY2 ? maxY1 : maxY2) * 1.2;

    return Stack(
      children: [
        // Bar chart for fines
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY : 500,
            minY: 0,
            barGroups: dataList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final days =
                  (item['time'] as DateTime).difference(_startTime).inDays;
              final value = item['value1'] as double;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: Colors.yellow.withOpacity(0.5),
                    width: 12, // Increased width for larger chart
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48, // Increased for larger font
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36, // Increased for larger font
                  interval: maxX > 7 ? maxX / 7 : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= dataList.length) return const Text('');
                    final date = dataList[index]['time'] as DateTime;
                    return Text(
                      DateFormat('MM-dd').format(date),
                      style: const TextStyle(color: Colors.black, fontSize: 14),
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
                  if (groupIndex >= dataList.length) return null;
                  final date = dataList[groupIndex]['time'] as DateTime;
                  return BarTooltipItem(
                    '${DateFormat('yyyy-MM-dd').format(date)}\nFines: ${rod.toY.toInt()}',
                    const TextStyle(color: Colors.white, fontSize: 14),
                  );
                },
              ),
            ),
          ),
        ),
        // Line chart for fines and points
        LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: dataList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return FlSpot(index.toDouble(), item['value1'] as double);
                }).toList(),
                isCurved: false,
                color: Colors.yellow,
                barWidth: 3,
                // Increased width for larger chart
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: dataList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return FlSpot(index.toDouble(), item['value2'] as double);
                }).toList(),
                isCurved: false,
                color: Colors.green,
                barWidth: 3,
                // Increased width for larger chart
                dotData: const FlDotData(show: false),
              ),
            ],
            minX: 0,
            maxX: dataList.length - 1.0,
            minY: 0,
            maxY: maxY > 0 ? maxY : 500,
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots
                    .map((spot) {
                      final index = spot.x.toInt();
                      if (index >= dataList.length) return null;
                      final date = dataList[index]['time'] as DateTime;
                      final label = spot.barIndex == 0 ? 'Fines' : 'Points';
                      return LineTooltipItem(
                        '${DateFormat('yyyy-MM-dd').format(date)}\n$label: ${spot.y.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 14),
                      );
                    })
                    .whereType<LineTooltipItem>()
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
