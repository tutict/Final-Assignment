import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';

class PieChart extends StatelessWidget {
  const PieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 200,
        child: ChartWidget(
          coordinateRender: ChartCircularCoordinateRender(
            charts: [
              Pie(
                data: dataList,
                position: (item) => (double.parse(item['value1'].toString())),
                holeRadius: 40,
                valueTextOffset: 20,
                centerTextStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                valueFormatter: (item) => item['value1'].toString(),
              ),
            ],
          ),
        ));
  }
}
