import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  var uuid = const Uuid();
  return uuid.v4();
}

/// 用户申诉页面
class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

class _UserAppealPageState extends State<UserAppealPage> {
  late AppealManagementControllerApi appealApi;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final TextEditingController _searchController = TextEditingController();
  List<AppealManagement> _appeals = [];
  bool _isLoading = true;
  bool _isUser = false; // 假设为普通用户（USER 角色）
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _loadAppealsAndCheckRole(); // 异步加载申诉和检查角色
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppealsAndCheckRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 检查用户角色（假设从后端获取）
      final roleResponse = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端提供用户信息
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (roleResponse.statusCode == 200) {
        final roleData = jsonDecode(roleResponse.body);
        _isUser = (roleData['roles'] as List<dynamic>).contains('USER');
        if (!_isUser) {
          throw Exception('权限不足：仅用户可访问此页面');
        }
      } else {
        throw Exception(
            '验证失败：${roleResponse.statusCode} - ${roleResponse.body}');
      }

      await _fetchUserAppeals(); // 仅加载当前用户的申诉
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _fetchUserAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 假设后端通过 JWT 自动过滤当前用户的申诉
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/appeals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appeals = list;
          _isLoading = false;
        });
      } else {
        throw Exception('加载用户申诉失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉记录失败: $e';
      });
    }
  }

  Future<void> _searchAppealsByName(String name) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      if (name.isEmpty) {
        await _fetchUserAppeals();
        return;
      }

      // 按申诉人姓名搜索（假设后端通过 JWT 过滤当前用户）
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/appeals/name/$name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appeals = list;
          _isLoading = false;
        });
      } else {
        throw Exception('搜索申诉失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索申诉失败: $e';
      });
    }
  }

  Future<void> _createAppeal(AppealManagement appeal) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final String idempotencyKey = generateIdempotencyKey();

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/appeals?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(appeal.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created 表示成功创建
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建申诉成功！')),
        );
        _fetchUserAppeals(); // 刷新列表
      } else {
        throw Exception(
            '创建申诉失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('创建申诉失败: $e')),
      );
    }
  }

  void _showCreateAppealDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idCardController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增申诉'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '申诉人姓名'),
              ),
              TextField(
                controller: idCardController,
                decoration: const InputDecoration(labelText: '身份证号码'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: '联系电话'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: '申诉原因'),
                maxLines: 3,
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

              if (name.isEmpty ||
                  idCard.isEmpty ||
                  contact.isEmpty ||
                  reason.isEmpty) {
                _showSnackBar('请填写所有必填字段');
                return;
              }

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
                appealId: null,
                offenseId: null,
                // 假设从上下文获取或用户选择（目前为空，后端可能需要默认值）
                appellantName: name,
                idCardNumber: idCard,
                contactNumber: contact,
                appealReason: reason,
                appealTime: DateTime.now().toIso8601String(),
                processStatus: 'Pending',
                // 初始状态为待处理
                processResult: '',
                // 初始结果为空
                idempotencyKey: idempotencyKey,
              );

              _createAppeal(newAppeal);
              Navigator.pop(ctx);
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isUser) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户申诉管理'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '按姓名搜索申诉',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isLight ? Colors.grey : Colors.grey[500]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isLight ? Colors.blue : Colors.blueGrey,
                        ),
                      ),
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    _searchAppealsByName(query);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _appeals.isEmpty
                    ? Center(
                        child: Text(
                          '暂无申诉记录',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _appeals.length,
                        itemBuilder: (context, index) {
                          final appeal = _appeals[index];
                          return Card(
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                '申诉人: ${appeal.appellantName ?? ""} (ID: ${appeal.appealId})',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '原因: ${appeal.appealReason ?? ""}\n状态: ${appeal.processStatus ?? "Pending"}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              // 用户无法编辑或删除，仅查看
                              trailing: null,
                              onTap: () {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAppealDialog, // 仅 USER 可以创建申诉
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        child: const Icon(Icons.add),
        tooltip: '新增申诉',
      ),
    );
  }
}

/// 申诉详情页面
class AppealDetailPage extends StatefulWidget {
  final AppealManagement appeal;

  const AppealDetailPage({super.key, required this.appeal});

  @override
  State<AppealDetailPage> createState() => _AppealDetailPageState();
}

class _AppealDetailPageState extends State<AppealDetailPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  AppealManagement? _updatedAppeal;
  bool _isUser = true; // 假设为用户（USER 角色）

  @override
  void initState() {
    super.initState();
    _updatedAppeal = widget.appeal;
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端提供用户信息
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        _isUser = (roleData['roles'] as List<dynamic>).contains('USER');
        if (!_isUser) {
          throw Exception('权限不足：仅用户可访问此页面');
        }
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isUser) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      _buildDetailRow(context, '申诉ID',
                          _updatedAppeal!.appealId?.toString() ?? '无'),
                      _buildDetailRow(
                          context, '上诉人', _updatedAppeal!.appellantName ?? '无'),
                      _buildDetailRow(context, '身份证号码',
                          _updatedAppeal!.idCardNumber ?? '无'),
                      _buildDetailRow(context, '联系电话',
                          _updatedAppeal!.contactNumber ?? '无'),
                      _buildDetailRow(
                          context, '原因', _updatedAppeal!.appealReason ?? '无'),
                      _buildDetailRow(
                          context, '时间', _updatedAppeal!.appealTime ?? '无'),
                      _buildDetailRow(context, '状态',
                          _updatedAppeal!.processStatus ?? 'Pending'),
                      _buildDetailRow(context, '处理结果',
                          _updatedAppeal!.processResult ?? '无'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
