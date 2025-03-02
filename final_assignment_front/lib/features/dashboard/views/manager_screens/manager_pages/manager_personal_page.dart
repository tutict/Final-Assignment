import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

class ManagerPersonalPage extends StatefulWidget {
  const ManagerPersonalPage({super.key});

  @override
  State<ManagerPersonalPage> createState() => _ManagerPersonalPageState();
}

class _ManagerPersonalPageState extends State<ManagerPersonalPage> {
  late UserManagementControllerApi userApi;
  late Future<UserManagement?> _managerFuture;
  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userApi = UserManagementControllerApi();
    _checkUserRole(); // 检查用户角色并加载管理员信息
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final userId = prefs.getString('userId'); // 假设存储了当前用户 ID
    if (jwtToken != null && userId != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端提供用户信息
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final userRole = (roleData['roles'] as List<dynamic>).firstWhere(
          (role) => role == 'ADMIN',
          orElse: () => 'USER',
        );

        setState(() {
          _isAdmin = userRole == 'ADMIN';
          if (_isAdmin) {
            _managerFuture = _fetchManagerInfo(userId);
          } else {
            _errorMessage = '权限不足：仅管理员可访问此页面';
            _isLoading = false;
            Get.offAllNamed(AppPages.login); // 非管理员跳转到登录页
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
          Get.offAllNamed(AppPages.login); // 验证失败跳转到登录页
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = '未登录，请重新登录';
        Get.offAllNamed(AppPages.login); // 未登录跳转到登录页
      });
    }
  }

  Future<UserManagement?> _fetchManagerInfo(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 使用后端 API 获取当前管理员用户信息
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final manager = UserManagement.fromJson(data);
        setState(() {
          _nameController.text = manager.name ?? '';
          _usernameController.text = manager.username ?? '';
          _passwordController.text = ''; // 密码不显示，需用户输入新密码
          _contactNumberController.text = manager.contactNumber ?? '';
          _emailController.text = manager.email ?? '';
          _remarksController.text = manager.remarks ?? '';
        });
        return manager;
      } else {
        throw Exception('获取管理员信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '获取管理员信息失败: $e';
      });
      return null;
    }
  }

  Future<void> _updateManagerInfo() async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final userId = prefs.getString('userId');
      if (jwtToken == null || userId == null) {
        throw Exception('No JWT token or userId found');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final updatedManager = UserManagement(
        userId: int.parse(userId),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        // 仅在有新密码时更新
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        status: (await _managerFuture)?.status ?? 'ACTIVE',
        // 保持现有状态
        createdTime: (await _managerFuture)?.createdTime,
        // 不更新创建时间
        modifiedTime: DateTime.now(),
        // 更新修改时间
        remarks: _remarksController.text.trim(),
        // 更新备注
        idempotencyKey: idempotencyKey, // 幂等键
      );

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/users/$userId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(updatedManager.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('个人信息更新成功！')),
        );
        _managerFuture = _fetchManagerInfo(userId); // 刷新数据
      } else {
        throw Exception(
            '更新失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      chatController.clearMessages();
    }
    Get.offAllNamed(AppPages.login);
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    inherit: true,
  );

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isAdmin) {
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

    return Obx(
      () => Theme(
        data: controller!.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('管理员个人页面'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts),
                onPressed: () {
                  Get.toNamed(AppPages.managerBusinessProcessing);
                },
                tooltip: '管理用户',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<UserManagement?>(
                    future: _managerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Center(
                          child: Text(
                            snapshot.hasError
                                ? '加载失败: ${snapshot.error}'
                                : '未找到管理员信息',
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                            ),
                          ),
                        );
                      } else {
                        final manager = snapshot.data!;
                        return ListView(
                          children: [
                            ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.blue),
                              title: Text(
                                '姓名',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading: const Icon(Icons.person_outline,
                                  color: Colors.blue),
                              title: Text(
                                '用户名',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.lock, color: Colors.blue),
                              title: Text(
                                '密码',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: '输入新密码（留空不修改）',
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                obscureText: true,
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.email, color: Colors.blue),
                              title: Text(
                                '邮箱',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.phone, color: Colors.blue),
                              title: Text(
                                '联系电话',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _contactNumberController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.note, color: Colors.blue),
                              title: Text(
                                '备注',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: TextField(
                                controller: _remarksController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color:
                                        isLight ? Colors.black87 : Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.grey
                                          : Colors.grey[500]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isLight
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                maxLines: 3,
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.info, color: Colors.blue),
                              title: Text(
                                '状态',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                manager.status ?? 'ACTIVE',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading: const Icon(Icons.calendar_today,
                                  color: Colors.blue),
                              title: Text(
                                '创建时间',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                manager.createdTime?.toString() ?? '无数据',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ListTile(
                              leading:
                                  const Icon(Icons.update, color: Colors.blue),
                              title: Text(
                                '修改时间',
                                style: TextStyle(
                                    color: currentTheme.colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                manager.modifiedTime?.toString() ?? '无数据',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: _updateManagerInfo,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 12.0),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor:
                                      currentTheme.colorScheme.primary,
                                ),
                                child:
                                    const Text('保存修改', style: _buttonTextStyle),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('登出'),
                                        content: const Text('确定要登出吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _logout();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 12.0),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                                child:
                                    const Text('退出登录', style: _buttonTextStyle),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
