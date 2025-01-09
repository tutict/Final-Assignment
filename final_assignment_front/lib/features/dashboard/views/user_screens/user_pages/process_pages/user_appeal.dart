import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  var uuid = const Uuid();
  return uuid.v4();
}

/// 用户申诉页面 (示例)
class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

class _UserAppealPageState extends State<UserAppealPage> {
  // 使用 AppealManagementControllerApi 来发起 HTTP 请求
  late AppealManagementControllerApi appealApi;

  // 用于搜索框
  final TextEditingController _searchController = TextEditingController();

  // 当前显示的申诉记录列表
  List<AppealManagement> _appeals = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _fetchAllAppeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取所有申诉
  Future<void> _fetchAllAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });


    try {
      final List<AppealManagement>? listObj = await appealApi.apiAppealsGet();
      setState(() {
        _appeals = listObj ?? [];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉记录失败: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉记录失败: $e';
      });
    }
  }

  /// 根据上诉人姓名进行搜索 (仅示例)
  Future<void> _searchAppealsByName(String name) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (name.isEmpty) {
        // 若搜索内容为空，加载全部
        await _fetchAllAppeals();
        return;
      }

      final Object? result = await appealApi.apiAppealsNameAppealNameGet(appealName: name);
      // 这个方法返回的是 Object? 可能是单个 or List
      // 需要看后端具体实现
      // 如果后端返回列表, 你可以把它当成 List<AppealManagement>.
      // 如果返回单个, 就转成 single item
      // 这里示例假设返回单条

      if (result is Map<String, dynamic>) {
        final singleAppeal = AppealManagement.fromJson(result);
        setState(() {
          _appeals = [singleAppeal];
          _isLoading = false;
        });
      } else if (result is List) {
        // 如果后端返回列表
        final appeals = result.map((item) => AppealManagement.fromJson(item as Map<String, dynamic>)).toList();
        setState(() {
          _appeals = appeals;
          _isLoading = false;
        });
      } else {
        // 不认识的格式
        setState(() {
          _appeals = [];
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索申诉失败: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索申诉失败: $e';
      });
    }
  }

  /// 创建新的申诉
  Future<void> _createAppeal(AppealManagement appeal) async {
    try {
      await appealApi.apiAppealsPost(appealManagement: appeal);
      // 创建成功后刷新列表
      await _fetchAllAppeals();
      _showSnackBar('创建申诉成功！');
    } on ApiException catch (e) {
      if (e.code == 409) {
        _showSnackBar('创建申诉重复：${e.message}');
      } else {
        _showSnackBar('创建申诉失败: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('创建申诉失败: $e');
    }
  }

  /// 删除申诉
  Future<void> _deleteAppeal(int appealId) async {
    try {
      await appealApi.apiAppealsAppealIdDelete(
        appealId: appealId.toString(),
      );
      // 删除成功后刷新
      await _fetchAllAppeals();
      _showSnackBar('删除申诉成功！');
    } on ApiException catch (e) {
      if (e.code == 409) {
        _showSnackBar('删除申诉请求重复：${e.message}');
      } else {
        _showSnackBar('删除申诉失败: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('删除申诉失败: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 简单示例UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户申诉管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 搜索
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '按姓名搜索申诉',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    _searchAppealsByName(query);
                  },
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 列表
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(child: Center(child: Text(_errorMessage)))
            else
              Expanded(
                child: _appeals.isEmpty
                    ? const Center(child: Text('暂无申诉记录'))
                    : ListView.builder(
                  itemCount: _appeals.length,
                  itemBuilder: (context, index) {
                    final appeal = _appeals[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                            '申诉人: ${appeal.appellantName ?? ""} (ID: ${appeal.appealId})'),
                        subtitle: Text(
                            '原因: ${appeal.appealReason ?? ""}\n状态: ${appeal.processStatus ?? ""}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            if (appeal.appealId != null) {
                              _deleteAppeal(appeal.appealId!);
                            }
                          },
                        ),
                        onTap: () {
                          // 点击可查看详情或编辑
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AppealDetailPage(appeal: appeal),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      // 浮动按钮：新增申诉
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateAppealDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 弹出对话框，输入申诉信息后创建
  void _showCreateAppealDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController idCardController = TextEditingController();
    final TextEditingController contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增申诉'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '申诉人姓名'),
              ),
              TextField(
                controller: idCardController,
                decoration: const InputDecoration(labelText: '身份证号码'),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: '联系电话'),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: '申诉原因'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final String name = nameController.text.trim();
              final String idCard = idCardController.text.trim();
              final String contact = contactController.text.trim();
              final String reason = reasonController.text.trim();

              if (name.isEmpty || idCard.isEmpty || contact.isEmpty || reason.isEmpty) {
                _showSnackBar('请填写所有必填字段');
                return;
              }

              // 示例：简单的身份证号码和联系电话格式验证
              final RegExp idCardRegExp = RegExp(r'^\d{15}|\d{18}$');
              final RegExp contactRegExp = RegExp(r'^\d{10,15}$');

              if (!idCardRegExp.hasMatch(idCard)) {
                _showSnackBar('身份证号码格式不正确');
                return;
              }

              if (!contactRegExp.hasMatch(contact)) {
                _showSnackBar('联系电话格式不正确');
                return;
              }

              final String idempotencyKey = generateIdempotencyKey();
              final AppealManagement newAppeal = AppealManagement(
                appealId: null, // 由后端生成
                offenseId: null, // 根据实际情况填充
                appellantName: name,
                idCardNumber: idCard,
                contactNumber: contact,
                appealReason: reason,
                appealTime: DateTime.now().toIso8601String(),
                processStatus: '处理中', // 初始状态
                processResult: '',
                idempotencyKey: idempotencyKey,
              );

              _createAppeal(newAppeal);
              Navigator.pop(ctx);
            },
            child: const Text('提交'),
          )
        ],
      ),
    );
  }
}

/// 申诉详情页 (示例)
class AppealDetailPage extends StatelessWidget {
  final AppealManagement appeal;

  const AppealDetailPage({super.key, required this.appeal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('申诉ID: ${appeal.appealId}'),
            Text('上诉人: ${appeal.appellantName}'),
            Text('身份证号码: ${appeal.idCardNumber}'),
            Text('联系电话: ${appeal.contactNumber}'),
            Text('原因: ${appeal.appealReason}'),
            Text('时间: ${appeal.appealTime}'),
            Text('状态: ${appeal.processStatus}'),
            Text('处理结果: ${appeal.processResult}'),
          ],
        ),
      ),
    );
  }
}
