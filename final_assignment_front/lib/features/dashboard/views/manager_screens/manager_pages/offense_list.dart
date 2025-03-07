import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPageState();
}

class _OffenseListPageState extends State<OffenseList> {
  late OffenseInformationControllerApi offenseApi;
  late Future<List<OffenseInformation>> _offensesFuture;
  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    offenseApi = OffenseInformationControllerApi();
    _offensesFuture = _fetchOffenses();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) throw Exception('No JWT token found');
    return {'Authorization': 'Bearer $jwtToken'};
  }

  Future<List<OffenseInformation>> _fetchOffenses({
    String? driverName,
    String? licensePlate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await offenseApi.initializeWithJwt(); // Assuming this method exists
      if (driverName != null && driverName.isNotEmpty) {
        final result = await offenseApi.apiOffensesDriverNameDriverNameGet(
            driverName: driverName);
        return _parseOffensesResult(result);
      } else if (licensePlate != null && licensePlate.isNotEmpty) {
        final result = await offenseApi.apiOffensesLicensePlateLicensePlateGet(
            licensePlate: licensePlate);
        return _parseOffensesResult(result);
      } else if (startTime != null && endTime != null) {
        final listObj = await offenseApi.apiOffensesTimeRangeGet(
          startTime: startTime.toIso8601String(),
          endTime: endTime.toIso8601String(),
        );
        return _parseOffensesList(listObj);
      } else {
        final listObj = await offenseApi.apiOffensesGet();
        return _parseOffensesList(listObj);
      }
    } catch (e) {
      debugPrint('获取违法行为信息失败: $e');
      throw Exception('获取违法行为信息失败: $e');
    }
  }

  Future<void> _deleteOffense(int offenseId) async {
    try {
      await offenseApi.initializeWithJwt();
      await offenseApi.apiOffensesOffenseIdDelete(
          offenseId: offenseId.toString());
      _showSnackBar('删除违法信息成功！');
      setState(() {
        _offensesFuture = _fetchOffenses();
      });
    } catch (e) {
      _showSnackBar('删除违法信息失败: $e');
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
          primaryColor: Theme.of(context).colorScheme.primary,
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _offensesFuture =
            _fetchOffenses(startTime: picked.start, endTime: picked.end);
      });
    }
  }

  List<OffenseInformation> _parseOffensesResult(Object? result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) =>
              OffenseInformation.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [OffenseInformation.fromJson(result)];
    } else {
      return [];
    }
  }

  List<OffenseInformation> _parseOffensesList(List<Object>? listObj) {
    if (listObj == null) return [];
    return listObj
        .map(
            (item) => OffenseInformation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Theme(
        data: controller?.currentBodyTheme.value ?? theme,
        child: Scaffold(
          appBar: AppBar(
            title: Text('违法行为列表',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDateRange,
                tooltip: '按时间范围搜索',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddOffensePage()))
                      .then((value) {
                    if (value == true && mounted) {
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
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _driverNameController,
                        decoration: InputDecoration(
                          labelText: '按司机姓名搜索',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                        onSubmitted: (value) =>
                            _searchOffensesByDriverName(value.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchOffensesByDriverName(
                          _driverNameController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _licensePlateController,
                        decoration: InputDecoration(
                          labelText: '按车牌号搜索',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                        onSubmitted: (value) =>
                            _searchOffensesByLicensePlate(value.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchOffensesByLicensePlate(
                          _licensePlateController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<OffenseInformation>>(
                    future: _offensesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text('加载违法行为时发生错误: ${snapshot.error}',
                                style: theme.textTheme.bodyLarge));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text('没有找到违法行为信息',
                                style: theme.textTheme.bodyLarge));
                      } else {
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
                              elevation: 4,
                              color: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: ListTile(
                                title: Text('违法类型: $type',
                                    style: theme.textTheme.bodyLarge),
                                subtitle: Text(
                                    '车牌号: $plate\n处理状态: $status\n时间: $time',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7))),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: theme.colorScheme.onSurface,
                                  onPressed: () {
                                    final id = offense.offenseId;
                                    if (id != null) _deleteOffense(id);
                                  },
                                  tooltip: '删除此违法行为',
                                ),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => OffenseDetailPage(
                                            offense: offense))),
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
          ),
        ),
      ),
    );
  }
}

class AddOffensePage extends StatelessWidget {
  const AddOffensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加新违法行为',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Center(
        child: Text('此页面用于添加新违法行为信息（尚未实现）', style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

class OffenseDetailPage extends StatelessWidget {
  final OffenseInformation offense;

  const OffenseDetailPage({super.key, required this.offense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = offense.offenseType ?? '未知类型';
    final plate = offense.licensePlate ?? '未知车牌';
    final status = offense.processStatus ?? '未知状态';
    final time = offense.offenseTime ?? '未知时间';

    return Obx(
      () => Theme(
        data: Get.isRegistered<UserDashboardController>()
            ? Get.find<UserDashboardController>().currentBodyTheme.value
            : theme,
        child: Scaffold(
          appBar: AppBar(
            title: Text('违法行为详细信息',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildDetailRow('违法类型', type, theme),
                _buildDetailRow('车牌号', plate, theme),
                _buildDetailRow('处理状态', status, theme),
                _buildDetailRow('违法时间', time, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}
