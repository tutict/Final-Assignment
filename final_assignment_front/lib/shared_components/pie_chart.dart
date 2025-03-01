import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart' as charts;

class TrafficViolationPieChart extends StatelessWidget {
  final Map<String, int> typeCountMap;

  const TrafficViolationPieChart({super.key, required this.typeCountMap});

  @override
  Widget build(BuildContext context) {
    if (typeCountMap.isEmpty) {
      return const Center(
        child: Text('No offense data available'),
      );
    }

    final dataList = typeCountMap.entries.map((entry) {
      return {
        'type': entry.key,
        'count': entry.value,
      };
    }).toList();

    // Generate a List<Color> based on the number of items in dataList
    final colors = List<Color>.generate(
      dataList.length,
          (index) => Colors.primaries[index % Colors.primaries.length][500]!,
    );

    return SizedBox(
      height: 300,
      child: charts.ChartWidget(
        coordinateRender: charts.ChartCircularCoordinateRender(
          margin: const EdgeInsets.all(16.0),
          charts: [
            charts.Pie(
              data: dataList,
              position: (item) => item['count'].toDouble(),
              colors: colors, // Pass a List<Color>
            ),
          ],
        ),
      ),
    );
  }
}