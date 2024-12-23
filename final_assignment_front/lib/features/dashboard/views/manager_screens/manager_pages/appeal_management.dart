// 根据你的项目实际路径修改
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/material.dart';

/// 管理员端申诉管理 (示例)
class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  late AppealManagementControllerApi appealApi;
  late Future<List<AppealManagement>> _appealsFuture;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _appealsFuture = _fetchAllAppeals();
  }

  /// 获取所有申诉
  Future<List<AppealManagement>> _fetchAllAppeals() async {
    try {
      final listObj = await appealApi.apiAppealsGet();
      if (listObj == null) return [];
      return listObj
          .map((item) =>
          AppealManagement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('加载申诉信息失败: $e');
    }
  }

  /// 根据申诉状态获取
  Future<void> _fetchAppealsByStatus(String status) async {
    try {
      if (status == '全部') {
        setState(() {
          _appealsFuture = _fetchAllAppeals();
        });
        return;
      }
      final listObj =
      await appealApi.apiAppealsStatusProcessStatusGet(processStatus: status);
      setState(() {
        if (listObj == null) {
          _appealsFuture = Future.value([]);
        } else {
          _appealsFuture = Future.value(listObj
              .map((item) =>
              AppealManagement.fromJson(item as Map<String, dynamic>))
              .toList());
        }
      });
    } catch (e) {
      _showSnackBar('获取申诉记录失败: $e');
    }
  }

  /// 更新申诉(示例：修改其状态)
  Future<void> _updateAppealStatus(int appealId, String newStatus) async {
    // 你的 PUT API： apiAppealsAppealIdPut({required String appealId, int? integer})
    // 看上去只能传一个 int? ...
    // 你可能需要改动后端或前端让它可以传 AppealManagement
    // 在此仅示例调用:

    try {
      await appealApi.apiAppealsAppealIdPut(
        appealId: appealId.toString(),
        integer: 0, // 仅示例
      );
      // 如果后端实际是更新 status，需要后端识别
      _showSnackBar('申诉状态已更新为: $newStatus');
      _refreshAppeals();
    } catch (e) {
      _showSnackBar('更新状态失败: $e');
    }
  }

  /// 删除申诉
  Future<void> _deleteAppeal(int appealId) async {
    try {
      await appealApi.apiAppealsAppealIdDelete(appealId: appealId.toString());
      _showSnackBar('删除成功');
      _refreshAppeals();
    } catch (e) {
      _showSnackBar('删除失败: $e');
    }
  }

  /// 刷新列表
  void _refreshAppeals() {
    setState(() {
      _appealsFuture = _fetchAllAppeals();
    });
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员端申诉管理'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _fetchAppealsByStatus(value);
            },
            itemBuilder: (context) {
              return ['全部', '处理中', '已批准', '已拒绝'].map((
                  String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AppealManagement>>(
        future: _appealsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('暂无申诉记录'));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final appeal = data[index];
              final aid = appeal.appealId ?? 0;
              final status = appeal.processStatus ?? '';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('申诉人: ${appeal.appellantName ?? ""}'),
                  subtitle: Text('原因: ${appeal.appealReason ?? ""}\n'
                      '状态: $status'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (choice) {
                      if (choice == '批准') {
                        _updateAppealStatus(aid, '已批准');
                      } else if (choice == '拒绝') {
                        _updateAppealStatus(aid, '已拒绝');
                      } else if (choice == '删除') {
                        _deleteAppeal(aid);
                      }
                    },
                    itemBuilder: (ctx) =>
                        ['批准', '拒绝', '删除']
                            .map((e) => PopupMenuItem(value: e, child: Text(e)))
                            .toList(),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) =>
                            AppealDetailAdminPage(appeal: appeal),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 管理员端查看申诉详情 (示例)
class AppealDetailAdminPage extends StatelessWidget {
  final AppealManagement appeal;

  const AppealDetailAdminPage({super.key, required this.appeal});

  @override
  Widget build(BuildContext context) {
    final status = appeal.processStatus ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('申诉详情')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('申诉ID: ${appeal.appealId}'),
            Text('姓名: ${appeal.appellantName ?? ""}'),
            Text('理由: ${appeal.appealReason ?? ""}'),
            Text('状态: $status'),
          ],
        ),
      ),
    );
  }
}
