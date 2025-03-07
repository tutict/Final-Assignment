import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class ManagerPersonalPage extends StatefulWidget {
  const ManagerPersonalPage({super.key});

  @override
  State<ManagerPersonalPage> createState() => _ManagerPersonalPageState();
}

class _ManagerPersonalPageState extends State<ManagerPersonalPage> {
  late UserManagementControllerApi userApi;
  late DriverInformationControllerApi driverApi;
  late Future<UserManagement?> _managerFuture;
  DriverInformation? _driverInfo;
  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    userApi = UserManagementControllerApi();
    driverApi = DriverInformationControllerApi();
    _scrollController = ScrollController();
    _managerFuture = Future.value(null);
    _checkUserRole();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      userApi.apiClient.setJwtToken(jwtToken);
      driverApi.apiClient.setJwtToken(jwtToken);

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      _isAdmin = roles.contains('ADMIN');
      if (!_isAdmin) {
        throw Exception('权限不足：此页面仅限 ADMIN 角色访问');
      }

      await _loadCurrentManager();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
      Get.offAllNamed(AppPages.login);
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT format');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT Decode Error: $e');
      return {};
    }
  }

  Future<void> _loadCurrentManager() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userResponse = await userApi.apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        {},
        {},
        'application/json',
        ['bearerAuth'],
      );
      if (userResponse.statusCode != 200) {
        throw Exception('加载管理员信息失败: ${userResponse.statusCode}');
      }

      final userData = jsonDecode(userResponse.body);
      final manager = UserManagement.fromJson(userData);

      DriverInformation? driverInfo;
      if (manager.userId != null) {
        try {
          driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: manager.userId.toString());
        } catch (e) {
          if (e.toString().contains('404')) {
            final String idempotencyKey = generateIdempotencyKey();
            driverInfo = DriverInformation(
              name: manager.username ?? 'Unknown',
              contactNumber: manager.contactNumber ?? '',
              idCardNumber: '',
            );
            driverInfo = await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: idempotencyKey,
            );
          } else {
            rethrow;
          }
        }
        _driverInfo = driverInfo;
      }

      setState(() {
        _managerFuture = Future.value(manager);
        _nameController.text = driverInfo?.name ?? '';
        _usernameController.text = manager.username ?? '';
        _passwordController.text = '';
        _contactNumberController.text =
            driverInfo?.contactNumber ?? manager.contactNumber ?? '';
        _emailController.text = manager.email ?? '';
        _remarksController.text = manager.remarks ?? '';
        _isLoading = false;
      });
      controller?.updateCurrentUser(
          driverInfo?.name ?? '', manager.username ?? '');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载管理员信息失败: $e';
      });
    }
  }

  Future<void> _updateField(String field, String value) async {
    if (!mounted ||
        (_driverInfo == null && (field == 'name' || field == 'contactNumber')))
      return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      final String idempotencyKey = generateIdempotencyKey();
      final currentManager = await _managerFuture;
      if (currentManager == null) {
        throw Exception('未找到当前管理员信息');
      }

      switch (field) {
        case 'name':
          final response = await driverApi.apiClient.invokeAPI(
            '/api/drivers/${_driverInfo!.driverId}/name?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          if (response.statusCode != 200) throw Exception('更新姓名失败');
          _driverInfo = DriverInformation.fromJson(jsonDecode(response.body));
          break;
        case 'contactNumber':
          final response = await driverApi.apiClient.invokeAPI(
            '/api/drivers/${_driverInfo!.driverId}/contactNumber?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          if (response.statusCode != 200) throw Exception('更新联系电话失败');
          _driverInfo = DriverInformation.fromJson(jsonDecode(response.body));
          break;
        case 'password':
          final response = await userApi.apiClient.invokeAPI(
            '/api/users/me/password?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          if (response.statusCode != 200) throw Exception('更新密码失败');
          break;
        case 'email':
          final response = await userApi.apiClient.invokeAPI(
            '/api/users/me/email?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          if (response.statusCode != 200) throw Exception('更新邮箱失败');
          break;
        case 'remarks':
          final response = await userApi.apiClient.invokeAPI(
            '/api/users/me/remarks?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          if (response.statusCode != 200) throw Exception('更新备注失败');
          break;
        default:
          throw Exception('未知字段: $field');
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('更新成功！')));
      await _loadCurrentManager();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('更新失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().clearMessages();
    }
    Get.offAllNamed(AppPages.login);
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
    final isLight = controller?.currentTheme.value == 'Light' ?? true;
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer
            : themeData.colorScheme.surfaceContainerHigh,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300.0, minHeight: 150.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
                      style: themeData.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                            themeData.colorScheme.primary),
                        foregroundColor: WidgetStateProperty.all(
                            themeData.colorScheme.onPrimary),
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

  @override
  Widget build(BuildContext context) {
    final isLight = controller?.currentTheme.value == 'Light' ?? true;
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

    if (!_isAdmin) {
      return CupertinoPageScaffold(
        backgroundColor: isLight
            ? themeData.colorScheme.surface.withOpacity(0.95)
            : themeData.colorScheme.surface.withOpacity(0.85),
        child: Center(
          child: Text(
            _errorMessage.isNotEmpty ? _errorMessage : '此页面仅限 ADMIN 角色访问',
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
          '管理员个人信息管理',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(
            CupertinoIcons.back,
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
          ),
        ),
        trailing: GestureDetector(
          onTap: () => Get.toNamed(AppPages.managerBusinessProcessing),
          child: Icon(
            CupertinoIcons.person_2,
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
                future: _managerFuture,
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
                                ? '加载失败: ${snapshot.error}'
                                : '未找到管理员信息',
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
                            onPressed: _loadCurrentManager,
                            style:
                                themeData.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                  themeData.colorScheme.primary),
                              foregroundColor: WidgetStateProperty.all(
                                  themeData.colorScheme.onPrimary),
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
                    final manager = snapshot.data!;
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
                            subtitle: _driverInfo?.name ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () {
                              _nameController.text = _driverInfo?.name ?? '';
                              _showEditDialog('姓名', _nameController,
                                  (value) => _updateField('name', value));
                            },
                          ),
                          _buildListTile(
                            title: '用户名',
                            subtitle: manager.username ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                          ),
                          _buildListTile(
                            title: '密码',
                            subtitle: '点击修改密码',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () {
                              _passwordController.clear();
                              _showEditDialog('密码', _passwordController,
                                  (value) => _updateField('password', value));
                            },
                          ),
                          _buildListTile(
                            title: '联系电话',
                            subtitle: _driverInfo?.contactNumber ??
                                manager.contactNumber ??
                                '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () {
                              _contactNumberController.text =
                                  _driverInfo?.contactNumber ??
                                      manager.contactNumber ??
                                      '';
                              _showEditDialog(
                                  '联系电话',
                                  _contactNumberController,
                                  (value) =>
                                      _updateField('contactNumber', value));
                            },
                          ),
                          _buildListTile(
                            title: '邮箱地址',
                            subtitle: manager.email ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () {
                              _emailController.text = manager.email ?? '';
                              _showEditDialog('邮箱地址', _emailController,
                                  (value) => _updateField('email', value));
                            },
                          ),
                          _buildListTile(
                            title: '状态',
                            subtitle: manager.status ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                          ),
                          _buildListTile(
                            title: '创建时间',
                            subtitle: manager.createdTime?.toString() ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                          ),
                          _buildListTile(
                            title: '修改时间',
                            subtitle: manager.modifiedTime?.toString() ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                          ),
                          _buildListTile(
                            title: '备注',
                            subtitle: manager.remarks ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () {
                              _remarksController.text = manager.remarks ?? '';
                              _showEditDialog('备注', _remarksController,
                                  (value) => _updateField('remarks', value));
                            },
                          ),
                          const SizedBox(height: 24.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: _logout,
                              style:
                                  themeData.elevatedButtonTheme.style?.copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                    themeData.colorScheme.error),
                                foregroundColor: WidgetStateProperty.all(
                                    themeData.colorScheme.onError),
                              ),
                              child: Text(
                                '退出登录',
                                style: themeData.textTheme.labelLarge?.copyWith(
                                  color: themeData.colorScheme.onError,
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
                },
              ),
      ),
    );
  }
}
