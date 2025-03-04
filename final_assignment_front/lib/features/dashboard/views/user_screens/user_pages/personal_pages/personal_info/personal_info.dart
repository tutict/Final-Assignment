import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:flutter/cupertino.dart';
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

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  late Future<UserManagement?> _userFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  bool _isUser = false; // 假设为普通用户（USER 角色）
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 检查用户角色并加载用户信息
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 检查用户角色（假设从后端获取）
      final roleResponse = await http.get(
        Uri.parse('http://localhost:8081/api/roles'), // 后端提供用户信息
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

      await _loadCurrentUser(); // 仅加载当前用户的用户信息
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('username'); // 从 SharedPreferences 获取用户名
      if (jwtToken == null || username == null) {
        throw Exception('No JWT token or username found');
      }

      // 使用后端 API 获取当前用户信息
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserManagement.fromJson(data);
        setState(() {
          _userFuture = Future.value(user);
          _nameController.text = user.name ?? '';
          _usernameController.text = user.username ?? '';
          _passwordController.text = ''; // 密码不显示，需用户输入新密码
          _contactNumberController.text = user.contactNumber ?? '';
          _emailController.text = user.email ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('加载用户信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载用户信息失败: $e';
      });
    }
  }

  Future<void> _updateUserInfo() async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final user = UserManagement(
        userId: (await _userFuture)?.userId,
        // 保持现有的 userId
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        // 仅在有新密码时更新
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        status: (await _userFuture)?.status ?? 'ACTIVE',
        // 保持现有状态
        createdTime: (await _userFuture)?.createdTime,
        // 不更新创建时间
        modifiedTime: DateTime.now(),
        // 更新修改时间
        remarks: (await _userFuture)?.remarks,
        // 保持现有备注
        idempotencyKey: idempotencyKey, // 幂等键
      );

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/users/me?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('用户信息更新成功！')),
        );
        await _loadCurrentUser(); // 刷新用户信息
      } else {
        throw Exception(
            '更新失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('更新用户信息失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isUser) {
      return CupertinoPageScaffold(
        backgroundColor: isLight
            ? CupertinoColors.white.withOpacity(0.9)
            : CupertinoColors.black.withOpacity(0.4),
        child: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? CupertinoColors.black : CupertinoColors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : CupertinoColors.black.withOpacity(0.4),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '用户信息管理',
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(Routes.personalMain);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
            isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : FutureBuilder<UserManagement?>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              snapshot.hasError
                                  ? '加载用户信息失败: ${snapshot.error}'
                                  : '没有找到用户信息',
                              style: TextStyle(
                                color: isLight
                                    ? CupertinoColors.black
                                    : CupertinoColors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            CupertinoButton(
                              onPressed: _loadCurrentUser,
                              child: const Text('重试'), // 允许用户重试
                            ),
                          ],
                        ),
                      );
                    } else {
                      final userInfo = snapshot.data!;
                      return _buildUserInfoList(userInfo, isLight);
                    }
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfoList(UserManagement userInfo, bool isLight) {
    return ListView(
      children: [
        CupertinoListTile(
          title: const Text('姓名'),
          subtitle: Text(userInfo.name ?? '无数据'),
          onTap: () {
            _nameController.text = userInfo.name ?? '';
            _showEditDialog('姓名', _nameController, (value) {
              userInfo.name = value;
              _updateUserInfo();
            });
          },
        ),
        CupertinoListTile(
          title: const Text('用户名'),
          subtitle: Text(userInfo.username ?? '无数据'),
          onTap: () {
            _usernameController.text = userInfo.username ?? '';
            _showEditDialog('用户名', _usernameController, (value) {
              userInfo.username = value;
              _updateUserInfo();
            });
          },
        ),
        CupertinoListTile(
          title: const Text('密码'),
          subtitle: const Text('点击修改密码'),
          onTap: () {
            _passwordController.clear();
            _showEditDialog('新密码', _passwordController, (value) {
              userInfo.password = value; // 假设密码直接更新，需加密处理
              _updateUserInfo();
            });
          },
        ),
        CupertinoListTile(
          title: const Text('联系电话'),
          subtitle: Text(userInfo.contactNumber ?? '无数据'),
          onTap: () {
            _contactNumberController.text = userInfo.contactNumber ?? '';
            _showEditDialog('联系电话', _contactNumberController, (value) {
              userInfo.contactNumber = value;
              _updateUserInfo();
            });
          },
        ),
        CupertinoListTile(
          title: const Text('邮箱'),
          subtitle: Text(userInfo.email ?? '无数据'),
          onTap: () {
            _emailController.text = userInfo.email ?? '';
            _showEditDialog('邮箱', _emailController, (value) {
              userInfo.email = value;
              _updateUserInfo();
            });
          },
        ),
        CupertinoListTile(
          title: const Text('状态'),
          subtitle: Text(userInfo.status ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('创建时间'),
          subtitle: Text(userInfo.createdTime?.toString() ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('修改时间'),
          subtitle: Text(userInfo.modifiedTime?.toString() ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('备注'),
          subtitle: Text(userInfo.remarks ?? '无数据'),
          onTap: () {
            _showEditDialog(
                '备注', TextEditingController(text: userInfo.remarks ?? ''),
                (value) {
              userInfo.remarks = value;
              _updateUserInfo();
            });
          },
        ),
        const SizedBox(height: 20.0),
        CupertinoButton.filled(
          onPressed: _updateUserInfo,
          child: const Text('保存所有更改'),
        ),
      ],
    );
  }

  void _showEditDialog(String field, TextEditingController controller,
      void Function(String) onSave) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('编辑 $field'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: '输入新的 $field',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('保存'),
            onPressed: () {
              Navigator.pop(context);
              onSave(controller.text.trim());
            },
          ),
        ],
      ),
    );
  }
}
