import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalMainPage> {
  late Future<UserManagement?> _userFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final ApiClient apiClient = ApiClient();
  bool _isLoading = true;
  bool _isUser = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkUserRole();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwtToken');
      debugPrint('JWT Token in _checkUserRole: $jwtToken');
      if (jwtToken == null) {
        jwtToken = await _loginAndGetToken();
        if (jwtToken == null) {
          throw Exception('No JWT token found after login attempt');
        }
      }
      apiClient.setJwtToken(jwtToken);

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      debugPrint('Decoded JWT roles: $roles');
      _isUser = roles.contains('USER');
      if (!_isUser) {
        throw Exception('权限不足：此页面仅限 USER 角色访问');
      }

      final response = await apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        {},
        {},
        'application/json',
        ['bearerAuth'],
      );
      debugPrint('User Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }

      await _loadCurrentUser();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT format');
      }
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT Decode Error: $e');
      return {};
    }
  }

  Future<String?> _loginAndGetToken() async {
    try {
      final response = await apiClient.invokeAPI(
        '/api/auth/login',
        'POST',
        [],
        {"username": "hgl@hgl.com", "password": "123456"},
        {},
        {},
        'application/json',
        [],
      );
      debugPrint('Login Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jwtToken = data['jwtToken'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', jwtToken);
        controller.updateCurrentUser('hgl@hgl.com', 'hgl@hgl.com');
        return jwtToken;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
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
      debugPrint('JWT Token in _loadCurrentUser: $jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }
      apiClient.setJwtToken(jwtToken);

      final response = await apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        {},
        {},
        'application/json',
        ['bearerAuth'],
      );
      debugPrint('User Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserManagement.fromJson(data);
        setState(() {
          _userFuture = Future.value(user);
          _nameController.text = user.name ?? '';
          _usernameController.text = user.username ?? '';
          _passwordController.text = '';
          _contactNumberController.text = user.contactNumber ?? '';
          _emailController.text = user.email ?? '';
          _isLoading = false;
        });
        controller.updateCurrentUser(
          user.name ?? '',
          user.username ?? '',
        );
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
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }
      apiClient.setJwtToken(jwtToken);

      final String idempotencyKey = generateIdempotencyKey();
      final user = UserManagement(
        userId: (await _userFuture)?.userId,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        status: (await _userFuture)?.status ?? 'ACTIVE',
        createdTime: (await _userFuture)?.createdTime,
        modifiedTime: DateTime.now(),
        remarks: (await _userFuture)?.remarks,
        idempotencyKey: idempotencyKey,
      );

      final response = await apiClient.invokeAPI(
        '/api/users/me?idempotencyKey=$idempotencyKey',
        'PUT',
        [],
        user.toJson(),
        {},
        {},
        'application/json',
        ['bearerAuth'],
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('用户信息更新成功！')),
        );
        controller.updateCurrentUser(
          user.name ?? '',
          user.username ?? '',
        );
        await _loadCurrentUser();
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
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;

    if (!_isUser) {
      return CupertinoPageScaffold(
        backgroundColor: isLight
            ? themeData.colorScheme.surface.withOpacity(0.95)
            : themeData.colorScheme.surface.withOpacity(0.85),
        child: Center(
          child: Text(
            _errorMessage.isNotEmpty ? _errorMessage : '此页面仅限 USER 角色访问',
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? themeData.colorScheme.surface.withOpacity(0.95)
          : themeData.colorScheme.surface.withOpacity(0.85),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '用户信息管理',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(Routes.personalMain);
          },
          child: Icon(
            CupertinoIcons.back,
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
          ),
        ),
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer.withOpacity(0.9)
            : themeData.colorScheme.surfaceContainer.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? themeData.colorScheme.outline.withOpacity(0.2)
                : themeData.colorScheme.outline.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: themeData.colorScheme.primary,
                  radius: 16.0,
                ),
              )
            : FutureBuilder<UserManagement?>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    );
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
                            style: themeData.textTheme.bodyLarge?.copyWith(
                              color: isLight
                                  ? themeData.colorScheme.onSurface
                                  : themeData.colorScheme.onSurface
                                      .withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: _loadCurrentUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                            ),
                            child: Text(
                              '重试',
                              style: themeData.textTheme.labelLarge?.copyWith(
                                color: themeData.colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final userInfo = snapshot.data!;
                    return _buildUserInfoList(userInfo, isLight, themeData);
                  }
                },
              ),
      ),
    );
  }

  Widget _buildUserInfoList(
      UserManagement userInfo, bool isLight, ThemeData themeData) {
    return CupertinoScrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6.0,
      thicknessWhileDragging: 10.0,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildListTile(
            title: '姓名',
            subtitle: userInfo.name ?? '无数据',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _nameController.text = userInfo.name ?? '';
              _showEditDialog('姓名', _nameController, (value) {
                userInfo.name = value;
                _updateUserInfo();
              });
            },
          ),
          _buildListTile(
            title: '用户名',
            subtitle: userInfo.username ?? '无数据',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _usernameController.text = userInfo.username ?? '';
              _showEditDialog('用户名', _usernameController, (value) {
                userInfo.username = value;
                _updateUserInfo();
              });
            },
          ),
          _buildListTile(
            title: '密码',
            subtitle: '点击修改密码',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _passwordController.clear();
              _showEditDialog('新密码', _passwordController, (value) {
                userInfo.password = value;
                _updateUserInfo();
              });
            },
          ),
          _buildListTile(
            title: '联系电话',
            subtitle: userInfo.contactNumber ?? '无数据',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _contactNumberController.text = userInfo.contactNumber ?? '';
              _showEditDialog('联系电话', _contactNumberController, (value) {
                userInfo.contactNumber = value;
                _updateUserInfo();
              });
            },
          ),
          _buildListTile(
            title: '邮箱',
            subtitle: userInfo.email ?? '无数据',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _emailController.text = userInfo.email ?? '';
              _showEditDialog('邮箱', _emailController, (value) {
                userInfo.email = value;
                _updateUserInfo();
              });
            },
          ),
          _buildListTile(
            title: '状态',
            subtitle: userInfo.status ?? '无数据',
            themeData: themeData,
            isLight: isLight,
          ),
          _buildListTile(
            title: '创建时间',
            subtitle: userInfo.createdTime?.toString() ?? '无数据',
            themeData: themeData,
            isLight: isLight,
          ),
          _buildListTile(
            title: '修改时间',
            subtitle: userInfo.modifiedTime?.toString() ?? '无数据',
            themeData: themeData,
            isLight: isLight,
          ),
          _buildListTile(
            title: '备注',
            subtitle: userInfo.remarks ?? '无数据',
            themeData: themeData,
            isLight: isLight,
            onTap: () {
              _showEditDialog(
                  '备注', TextEditingController(text: userInfo.remarks ?? ''),
                  (value) {
                userInfo.remarks = value;
                _updateUserInfo();
              });
            },
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _updateUserInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
                elevation: 4,
                shadowColor: themeData.colorScheme.shadow.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 14.0),
              ),
              child: Text(
                '保存所有更改',
                style: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required ThemeData themeData,
    required bool isLight,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
      color: isLight
          ? themeData.colorScheme.surfaceContainerLow
          : themeData.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(
          title,
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurfaceVariant
                : themeData.colorScheme.onSurfaceVariant.withOpacity(0.85),
          ),
        ),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  void _showEditDialog(String field, TextEditingController textController,
      void Function(String) onSave) {
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer
            : themeData.colorScheme.surfaceContainerHigh,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300.0, // 限制最大宽度
            minHeight: 150.0, // 最小高度
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0), // 缩小内边距
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '编辑 $field',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: textController,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                  ),
                  decoration: InputDecoration(
                    hintText: '输入新的 $field',
                    hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.6)
                          : themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? themeData.colorScheme.surfaceContainerLowest
                        : themeData.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: themeData.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0), // 缩小输入框内边距
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: themeData.colorScheme.onSurface,
                      ),
                      child: Text(
                        '取消',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: themeData.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onSave(textController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: themeData.colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0), // 缩小按钮
                      ),
                      child: Text(
                        '保存',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: themeData.colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
