import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart' as charts;
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';

class OffensePieChartPage extends StatefulWidget {
  const OffensePieChartPage({super.key});

  @override
  State<OffensePieChartPage> createState() => _OffensePieChartPageState();
}

class _OffensePieChartPageState extends State<OffensePieChartPage> {
  late OffenseInformationControllerApi offenseApi;
  late Future<List<OffenseInformation>> _offensesFuture;

  @override
  void initState() {
    super.initState();
    offenseApi = OffenseInformationControllerApi();
    _offensesFuture = _fetchAllOffenses();
  }

  Future<List<OffenseInformation>> _fetchAllOffenses() async {
    try {
      final listObj = await offenseApi.apiOffensesGet();
      if (listObj == null) return [];
      return listObj.map((item) {
        return OffenseInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch offense information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offense Pie Chart (flutter_chart_plus)'),
      ),
      body: FutureBuilder<List<OffenseInformation>>(
        future: _offensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load offense data: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No offense data available'),
            );
          } else {
            final offenses = snapshot.data!;
            final typeCountMap = _buildTypeCount(offenses);

            final dataList = typeCountMap.entries.map((entry) {
              return {
                'type': entry.key,
                'count': entry.value,
              };
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: charts.ChartWidget(
                coordinateRender: charts.ChartCircularCoordinateRender(
                  margin: const EdgeInsets.all(16.0),
                  charts: [
                    charts.Pie(
                      data: dataList,
                      position: (item) => item['count'].toDouble(),
                      // Configure other parameters as per the package's documentation
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Map<String, int> _buildTypeCount(List<OffenseInformation> offenses) {
    final Map<String, int> map = {};
    for (var o in offenses) {
      final type = o.offenseType ?? 'Unknown Type';
      map[type] = (map[type] ?? 0) + 1;
    }
    return map;
  }
}
