import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
  UserManagement? _currentManager;
  DriverInformation? _driverInfo;
  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;
  bool _isLoading = true;
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
    _loadCurrentManager();
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

  Future<void> _loadCurrentManager() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      debugPrint('JWT Token: $jwtToken');
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT Token not found in SharedPreferences');
      }

      await userApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      debugPrint('UserManagement and Driver APIs initialized with JWT');

      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub']?.toString();
      if (username == null || username.isEmpty) {
        throw Exception('未能从凭证中解析当前用户');
      }

      final manager =
          await userApi.apiUsersUsernameUsernameGet(username: username);
      if (manager == null || manager.userId == null) {
        throw Exception('未找到当前用户信息');
      }

      DriverInformation? driverInfo =
          await driverApi.apiDriversDriverIdGet(driverId: manager.userId!);
      if (driverInfo == null) {
        final idempotencyKey = generateIdempotencyKey();
        final newDriver = DriverInformation(
          driverId: manager.userId,
          name: manager.username ?? '未知用户',
          contactNumber: manager.contactNumber ?? '',
          idCardNumber: '',
        );
        debugPrint(
            'Creating driver profile for user ${manager.userId} (${manager.username})');
        await driverApi.apiDriversPost(
          driverInformation: newDriver,
          idempotencyKey: idempotencyKey,
        );
        driverInfo =
            await driverApi.apiDriversDriverIdGet(driverId: manager.userId!);
      }

      _driverInfo = driverInfo;
      _currentManager = manager;

      if (mounted) {
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
      }
      controller?.updateCurrentUser(
          driverInfo?.name ?? '', manager.username ?? '');
    } catch (e) {
      debugPrint('Load current manager error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_errorMessage.isEmpty) {
            _errorMessage = _formatErrorMessage(e);
          }
        });
      }
    }
  }

  Future<void> _updateField(String field, String value) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final currentManager = _currentManager ?? await _managerFuture;
      if (currentManager == null || currentManager.userId == null) {
        throw Exception('未找到当前用户信息');
      }
      final userId = currentManager.userId!;
      final idempotencyKey = generateIdempotencyKey();

      switch (field) {
        case 'name':
          await driverApi.apiDriversDriverIdNamePut(
            driverId: userId,
            name: value,
            idempotencyKey: idempotencyKey,
          );
          break;
        case 'contactNumber':
          await driverApi.apiDriversDriverIdContactNumberPut(
            driverId: userId,
            contactNumber: value,
            idempotencyKey: idempotencyKey,
          );
          break;
        case 'password':
          final updatedUser = currentManager.copyWith(password: value);
          await userApi.apiUsersUserIdPut(
            userId: userId.toString(),
            userManagement: updatedUser,
            idempotencyKey: idempotencyKey,
          );
          break;
        case 'email':
          final updatedUser = currentManager.copyWith(email: value);
          await userApi.apiUsersUserIdPut(
            userId: userId.toString(),
            userManagement: updatedUser,
            idempotencyKey: idempotencyKey,
          );
          break;
        case 'remarks':
          final updatedUser = currentManager.copyWith(remarks: value);
          await userApi.apiUsersUserIdPut(
            userId: userId.toString(),
            userManagement: updatedUser,
            idempotencyKey: idempotencyKey,
          );
          break;
        default:
          throw Exception('未知字段: $field');
      }

      await _loadCurrentManager();

      if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Update field error: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(_formatErrorMessage(e),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                              .withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withValues(alpha: 0.3)),
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
      return DashboardPageTemplate(
        theme: themeData,
        title: '个人信息管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onThemeToggle: controller?.toggleBodyTheme,
        actions: [
          DashboardPageBarAction(
            icon: Icons.logout,
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
        body: _buildBody(themeData),
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

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.error,
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
              _errorMessage.isNotEmpty ? _errorMessage : '未找到用户信息',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.error,
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
      shadowColor: themeData.colorScheme.shadow.withValues(alpha: 0.2),
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
        trailing: onTap != null
            ? Icon(Icons.edit, color: themeData.colorScheme.primary)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }
}
