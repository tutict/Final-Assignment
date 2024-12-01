import 'dart:convert';
import 'dart:developer' as developer;
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPage();
}

class _OffenseListPage extends State<OffenseList> {
  late Future<List<Offense>> _offensesFuture;

  @override
  void initState() {
    super.initState();
    _offensesFuture = _fetchOffenses();
  }

  Future<List<Offense>> _fetchOffenses({
    String? driverName,
    String? licensePlate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    Uri url;

    if (driverName != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.offenseInformationEndpoint}/driverName/$driverName');
    } else if (licensePlate != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.offenseInformationEndpoint}/licensePlate/$licensePlate');
    } else if (startTime != null && endTime != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.offenseInformationEndpoint}/timeRange?startTime=${startTime.toIso8601String()}&endTime=${endTime.toIso8601String()}');
    } else {
      url = Uri.parse('${AppConfig.baseUrl}${AppConfig.offenseInformationEndpoint}');
    }

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> offensesJson = jsonDecode(response.body);
        return offensesJson.map((json) => Offense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load offenses');
      }
    } catch (e) {
      developer.log('Error: $e');
      throw Exception('Failed to load offenses: $e');
    }
  }

  Future<void> _deleteOffense(int offenseId) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.offenseInformationEndpoint}/$offenseId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除违法信息成功！')),
        );
        setState(() {
          _offensesFuture = _fetchOffenses(); // Refresh offense list after delete
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除违法信息失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  void _searchOffensesByDriverName(String driverName) {
    setState(() {
      _offensesFuture = _fetchOffenses(driverName: driverName);
    });
  }

  void _searchOffensesByLicensePlate(String licensePlate) {
    setState(() {
      _offensesFuture = _fetchOffenses(licensePlate: licensePlate);
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _offensesFuture = _fetchOffenses(startTime: picked.start, endTime: picked.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('违法行为列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _selectDateRange,
            tooltip: '按时间范围搜索',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddOffensePage()),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _offensesFuture = _fetchOffenses();
                  });
                }
              });
            },
            tooltip: '添加新违法行为',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchOffensesByDriverName,
              decoration: const InputDecoration(
                labelText: '按司机姓名搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchOffensesByLicensePlate,
              decoration: const InputDecoration(
                labelText: '按车牌号搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Offense>>(
              future: _offensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('加载违法行为时发生错误: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到违法行为信息'));
                } else {
                  final offenses = snapshot.data!;
                  return ListView.builder(
                    itemCount: offenses.length,
                    itemBuilder: (context, index) {
                      final offense = offenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('违法类型: ${offense.offenseType}'),
                          subtitle: Text(
                              '车牌号: ${offense.licensePlate}\n处理状态: ${offense.processState}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteOffense(offense.offenseId),
                            tooltip: '删除此违法行为',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      OffenseDetailPage(offense: offense)),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddOffensePage extends StatelessWidget {
  const AddOffensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新违法行为'),
      ),
      body: const Center(
        child: Text('此页面用于添加新违法行为信息（尚未实现）'),
      ),
    );
  }
}

class OffenseDetailPage extends StatelessWidget {
  final Offense offense;

  const OffenseDetailPage({required this.offense, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('违法行为详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('违法类型: ${offense.offenseType}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('车牌号: ${offense.licensePlate}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('处理状态: ${offense.processState}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('违法时间: ${offense.offenseTime}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class Offense {
  final int offenseId;
  final String offenseType;
  final String licensePlate;
  final String processState;
  final String offenseTime;

  Offense({
    required this.offenseId,
    required this.offenseType,
    required this.licensePlate,
    required this.processState,
    required this.offenseTime,
  });

  factory Offense.fromJson(Map<String, dynamic> json) {
    return Offense(
      offenseId: json['offenseId'],
      offenseType: json['offenseType'],
      licensePlate: json['licensePlate'],
      processState: json['processState'],
      offenseTime: json['offenseTime'],
    );
  }
}
