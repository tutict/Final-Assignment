import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
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
      String? jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        jwtToken = await _loginAndGetToken();
        if (jwtToken == null) {
          throw Exception('未登录，请重新登录');
        }
      }
      await userApi.initializeWithJwt();
      await driverApi.initializeWithJwt();

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
        _errorMessage = _formatErrorMessage(e);
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

  Future<String?> _loginAndGetToken() async {
    try {
      final response = await userApi.apiClient.invokeAPI(
        '/api/auth/login',
        'POST',
        [],
        {"username": "admin@admin.com", "password": "admin123"},
        {},
        {},
        'application/json',
        [],
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final jwtToken = data['jwtToken'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', jwtToken);
        controller?.updateCurrentUser('admin@admin.com', 'admin@admin.com');
        return jwtToken;
      } else {
        throw Exception('登录失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  Future<void> _loadCurrentManager() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final manager = await userApi.apiUsersMeGet();
      if (manager == null) {
        throw Exception('未找到当前管理员信息');
      }

      DriverInformation? driverInfo;
      if (manager.userId != null) {
        try {
          driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: manager.userId.toString());
        } catch (e) {
          if (e is ApiException && e.code == 404) {
            final idempotencyKey = generateIdempotencyKey();
            driverInfo = DriverInformation(
              driverId: manager.userId, // Set driverId to match userId
              name: manager.username ?? '未知管理员',
              contactNumber: manager.contactNumber ?? '',
              idCardNumber: '',
            );
            debugPrint(
                'Creating new driver with driverId: ${manager.userId}, name: ${manager.username}');
            await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: idempotencyKey,
            );
            driverInfo = await driverApi.apiDriversDriverIdGet(
                driverId: manager.userId.toString());
            debugPrint('Driver created and fetched: ${driverInfo?.toJson()}');
          } else {
            setState(() {
              _errorMessage = _formatErrorMessage(e);
            });
            rethrow;
          }
        }
        _driverInfo = driverInfo;
      } else {
        throw Exception('管理员ID为空，无法加载或创建司机信息');
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
        if (_errorMessage.isEmpty) {
          _errorMessage = _formatErrorMessage(e);
        }
      });
    }
  }

  Future<void> _updateField(String field, String value) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final currentManager = await _managerFuture;
      if (currentManager == null) {
        throw Exception('未找到当前管理员信息');
      }
      final idempotencyKey = generateIdempotencyKey();

      switch (field) {
        case 'name':
          // Directly create a new driver regardless of existing data
          final newDriverName = DriverInformation(
            driverId: currentManager.userId, // e.g., match userId
            name: value, // New name value
            contactNumber: _driverInfo?.contactNumber ??
                currentManager.contactNumber ??
                '',
            idCardNumber: _driverInfo?.idCardNumber ?? '',
          );
          debugPrint(
              'Creating new driver with driverId: ${currentManager.userId}, name: $value');
          await driverApi.apiDriversPost(
            driverInformation: newDriverName,
            idempotencyKey: idempotencyKey,
          );
          _driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: currentManager.userId.toString());
          debugPrint('Driver created and fetched: ${_driverInfo?.toJson()}');
          break;

        case 'contactNumber':
          // Directly create a new driver regardless of existing data
          final newDriverContact = DriverInformation(
            driverId: currentManager.userId, // e.g., match userId
            name: _driverInfo?.name ?? currentManager.username ?? '未知管理员',
            contactNumber: value, // New contact number value
            idCardNumber: _driverInfo?.idCardNumber ?? '',
          );
          debugPrint(
              'Creating new driver with driverId: ${currentManager.userId}, contactNumber: $value');
          await driverApi.apiDriversPost(
            driverInformation: newDriverContact,
            idempotencyKey: idempotencyKey,
          );
          _driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: currentManager.userId.toString());
          debugPrint('Driver created and fetched: ${_driverInfo?.toJson()}');
          break;

        case 'password':
          await userApi.apiClient.invokeAPI(
            '/api/users/me/password?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          break;

        case 'email':
          await userApi.apiClient.invokeAPI(
            '/api/users/me/email?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          break;

        case 'remarks':
          await userApi.apiClient.invokeAPI(
            '/api/users/me/remarks?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {},
            {},
            'text/plain',
            ['bearerAuth'],
          );
          break;

        default:
          throw Exception('未知字段: $field');
      }

      // Refresh to get updated data
      await _loadCurrentManager();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('$field 更新成功！',
              style: TextStyle(
                  color: controller?.currentBodyTheme.value.colorScheme
                          .onPrimaryContainer ??
                      Colors.black)),
          backgroundColor:
              controller?.currentBodyTheme.value.colorScheme.primary ??
                  Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showConfirmationDialog('确认退出', '您确定要退出登录吗？');
    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().clearMessages();
    }
    Get.offAllNamed(AppPages.login);
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
            data: controller?.currentBodyTheme.value ?? ThemeData.light(),
            child: AlertDialog(
              backgroundColor: controller
                  ?.currentBodyTheme.value.colorScheme.surfaceContainer,
              title: Text(title,
                  style: TextStyle(
                      color: controller
                          ?.currentBodyTheme.value.colorScheme.onSurface)),
              content: Text(content,
                  style: TextStyle(
                      color: controller?.currentBodyTheme.value.colorScheme
                          .onSurfaceVariant)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消',
                      style: TextStyle(
                          color: controller
                              ?.currentBodyTheme.value.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('确定',
                      style: TextStyle(
                          color: controller
                              ?.currentBodyTheme.value.colorScheme.primary)),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _showEditDialog(String field, TextEditingController textController,
      void Function(String) onSave) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    showDialog(
      context: context,
      builder: (_) => Theme(
        data: themeData,
        child: Dialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 300.0, minHeight: 150.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '编辑 $field',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: textController,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '输入新的 $field',
                      hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.6)),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
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
                              fontSize: 14),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '管理员个人信息管理',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            trailing: GestureDetector(
              onTap: () => Get.toNamed(AppPages.managerBusinessProcessing),
              child: Icon(
                CupertinoIcons.person_2,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: _buildBody(themeData),
          ),
        ),
      );
    });
  }

  Widget _buildBody(ThemeData themeData) {
    if (_isLoading) {
      return Center(
        child: CupertinoActivityIndicator(
          color: themeData.colorScheme.primary,
          radius: 16.0,
        ),
      );
    }

    if (!_isAdmin) {
      return Center(
        child: Text(
          _errorMessage.isNotEmpty ? _errorMessage : '此页面仅限 ADMIN 角色访问',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
      );
    }

    return FutureBuilder<UserManagement?>(
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
            child: Text(
              snapshot.hasError
                  ? '加载失败: ${snapshot.error}'
                  : _errorMessage.isNotEmpty
                      ? _errorMessage
                      : '未找到管理员信息',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontSize: 18,
              ),
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
                ),
                _buildListTile(
                  title: '密码',
                  subtitle: '点击修改密码',
                  themeData: themeData,
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
                  onTap: () {
                    _contactNumberController.text =
                        _driverInfo?.contactNumber ??
                            manager.contactNumber ??
                            '';
                    _showEditDialog('联系电话', _contactNumberController,
                        (value) => _updateField('contactNumber', value));
                  },
                ),
                _buildListTile(
                  title: '邮箱地址',
                  subtitle: manager.email ?? '无数据',
                  themeData: themeData,
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
                ),
                _buildListTile(
                  title: '创建时间',
                  subtitle: manager.createdTime?.toString() ?? '无数据',
                  themeData: themeData,
                ),
                _buildListTile(
                  title: '修改时间',
                  subtitle: manager.modifiedTime?.toString() ?? '无数据',
                  themeData: themeData,
                ),
                _buildListTile(
                  title: '备注',
                  subtitle: manager.remarks ?? '无数据',
                  themeData: themeData,
                  onTap: () {
                    _remarksController.text = manager.remarks ?? '';
                    _showEditDialog('备注', _remarksController,
                        (value) => _updateField('remarks', value));
                  },
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required ThemeData themeData,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(
          title,
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }
}
