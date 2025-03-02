import 'package:flutter/material.dart';

// 导入你的 OffenseInformationControllerApi、OffenseInformation
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For JWT token

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPageState();
}

class _OffenseListPageState extends State<OffenseList> {
  // 用于调用后端接口
  late OffenseInformationControllerApi offenseApi;

  // Future 用于异步加载违法行为列表
  late Future<List<OffenseInformation>> _offensesFuture;

  @override
  void initState() {
    super.initState();
    offenseApi = OffenseInformationControllerApi();
    _offensesFuture = _fetchOffenses(); // Initial fetch without filters
  }

  /// 获取 JWT 令牌
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('No JWT token found');
    }
    return {'Authorization': 'Bearer $jwtToken'};
  }

  /// 根据可选条件（driverName, licensePlate, timeRange等）获取违法行为信息
  Future<List<OffenseInformation>> _fetchOffenses({
    String? driverName,
    String? licensePlate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final headers = await _getAuthHeaders(); // Get authentication headers

      // 1) 按司机姓名
      if (driverName != null && driverName.isNotEmpty) {
        final result = await offenseApi.apiOffensesDriverNameDriverNameGet(
          driverName: driverName,
          headers: headers, // Pass headers
        );
        return _parseOffensesResult(result);
      }
      // 2) 按车牌号
      else if (licensePlate != null && licensePlate.isNotEmpty) {
        final result = await offenseApi.apiOffensesLicensePlateLicensePlateGet(
          licensePlate: licensePlate,
          headers: headers, // Pass headers
        );
        return _parseOffensesResult(result);
      }
      // 3) 按时间范围
      else if (startTime != null && endTime != null) {
        final listObj = await offenseApi.apiOffensesTimeRangeGet(
          startTime: startTime.toIso8601String(),
          endTime: endTime.toIso8601String(),
          headers: headers, // Pass headers
        );
        return _parseOffensesList(listObj);
      }
      // 4) 否则获取所有
      else {
        final listObj =
            await offenseApi.apiOffensesGet(headers: headers); // Pass headers
        return _parseOffensesList(listObj);
      }
    } catch (e) {
      debugPrint('获取违法行为信息失败: $e');
      throw Exception('获取违法行为信息失败: $e');
    }
  }

  /// 删除违法行为
  Future<void> _deleteOffense(int offenseId) async {
    try {
      final headers = await _getAuthHeaders(); // Get authentication headers
      // 调用 apiOffensesOffenseIdDelete
      final responseObj = await offenseApi.apiOffensesOffenseIdDelete(
        offenseId: offenseId.toString(),
        headers: headers, // Pass headers
      );
      // 如果成功，刷新列表
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除违法信息成功！')),
      );
      setState(() {
        _offensesFuture = _fetchOffenses();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除违法信息失败: $e')),
      );
    }
  }

  /// 按司机姓名搜索
  void _searchOffensesByDriverName(String driverName) {
    setState(() {
      _offensesFuture = _fetchOffenses(driverName: driverName);
    });
  }

  /// 按车牌号搜索
  void _searchOffensesByLicensePlate(String licensePlate) {
    setState(() {
      _offensesFuture = _fetchOffenses(licensePlate: licensePlate);
    });
  }

  /// 弹窗选择时间范围
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _offensesFuture = _fetchOffenses(
          startTime: picked.start,
          endTime: picked.end,
        );
      });
    }
  }

  /// 解析单次查询结果: 可能返回单条(Map)或多条(List)
  List<OffenseInformation> _parseOffensesResult(Object? result) {
    if (result == null) return [];
    if (result is List) {
      return result.map((item) {
        return OffenseInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } else if (result is Map<String, dynamic>) {
      return [OffenseInformation.fromJson(result)];
    } else {
      return [];
    }
  }

  /// 解析后端返回的 List<Object>?
  List<OffenseInformation> _parseOffensesList(List<Object>? listObj) {
    if (listObj == null) return [];
    return listObj.map((item) {
      return OffenseInformation.fromJson(item as Map<String, dynamic>);
    }).toList();
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
          // 按司机姓名搜索
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
          // 按车牌号搜索
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
          // 列表
          Expanded(
            child: FutureBuilder<List<OffenseInformation>>(
              future: _offensesFuture,
              builder: (context, snapshot) {
                // 加载中
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 出错
                else if (snapshot.hasError) {
                  return Center(
                    child: Text('加载违法行为时发生错误: ${snapshot.error}'),
                  );
                }
                // 没数据
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到违法行为信息'));
                }
                // 有数据
                else {
                  final offenses = snapshot.data!;
                  return ListView.builder(
                    itemCount: offenses.length,
                    itemBuilder: (context, index) {
                      final offense = offenses[index];
                      final type = offense.offenseType ?? '未知类型';
                      final plate = offense.licensePlate ?? '未知车牌';
                      final status = offense.processStatus ?? '未知状态';
                      final time = offense.offenseTime ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('违法类型: $type'),
                          subtitle: Text('车牌号: $plate\n处理状态: $status'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              final id = offense.offenseId;
                              if (id != null) {
                                _deleteOffense(id);
                              }
                            },
                            tooltip: '删除此违法行为',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OffenseDetailPage(offense: offense),
                              ),
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

// 添加违法行为页面 (示例)
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

// 违法行为详情页 (示例)
class OffenseDetailPage extends StatelessWidget {
  final OffenseInformation offense;

  const OffenseDetailPage({super.key, required this.offense});

  @override
  Widget build(BuildContext context) {
    final type = offense.offenseType ?? '未知类型';
    final plate = offense.licensePlate ?? '未知车牌';
    final status = offense.processStatus ?? '未知状态';
    final time = offense.offenseTime ?? '未知时间';

    return Scaffold(
      appBar: AppBar(title: const Text('违法行为详细信息')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('违法类型: $type', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('车牌号: $plate', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('处理状态: $status', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('违法时间: $time', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
