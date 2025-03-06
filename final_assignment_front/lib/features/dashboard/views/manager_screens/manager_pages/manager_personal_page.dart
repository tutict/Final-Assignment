import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      debugPrint('JWT Token in _checkUserRole: $jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      userApi.apiClient.setJwtToken(jwtToken);

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      debugPrint('Decoded JWT roles: $roles');
      _isAdmin = roles.contains('ADMIN');
      if (!_isAdmin) {
        throw Exception('权限不足：此页面仅限 ADMIN 角色访问');
      }

      _managerFuture = _fetchManagerInfo();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
        Get.offAllNamed(AppPages.login);
      });
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

  Future<UserManagement?> _fetchManagerInfo() async {
    try {
      final user = await userApi.apiUsersMeGet();
      if (user != null) {
        setState(() {
          _nameController.text = user.name ?? '';
          _usernameController.text = user.username ?? '';
          _passwordController.text = '';
          _contactNumberController.text = user.contactNumber ?? '';
          _emailController.text = user.email ?? '';
          _remarksController.text = user.remarks ?? '';
        });
      }
      return user;
    } catch (e) {
      setState(() => _errorMessage = '获取管理员信息失败: $e');
      return null;
    }
  }

  Future<void> _updateManagerInfo() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');
      userApi.apiClient.setJwtToken(jwtToken);

      final currentUser = await _managerFuture;
      final updatedManager = UserManagement(
        userId: currentUser?.userId,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        status: currentUser?.status ?? 'ACTIVE',
        createdTime: currentUser?.createdTime,
        modifiedTime: DateTime.now(),
        remarks: _remarksController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      await userApi.apiUsersMePut(
          userManagement: updatedManager,
          idempotencyKey: updatedManager.idempotencyKey!);
      scaffoldMessenger
          .showSnackBar(const SnackBar(content: Text('个人信息更新成功！')));
      _managerFuture = _fetchManagerInfo();
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
                      style: TextButton.styleFrom(
                          foregroundColor: themeData.colorScheme.onSurface),
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
                            borderRadius: BorderRadius.circular(10.0)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
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
                    color: themeData.colorScheme.primary, radius: 16.0))
            : FutureBuilder<UserManagement?>(
                future: _managerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CupertinoActivityIndicator(
                            color: themeData.colorScheme.primary,
                            radius: 16.0));
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
                            onPressed: () =>
                                _managerFuture = _fetchManagerInfo(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
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
                            subtitle: manager.name ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () => _showEditDialog('姓名', _nameController,
                                (value) => _updateManagerInfo()),
                          ),
                          _buildListTile(
                            title: '用户名',
                            subtitle: manager.username ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () => _showEditDialog(
                                '用户名',
                                _usernameController,
                                (value) => _updateManagerInfo()),
                          ),
                          _buildListTile(
                            title: '密码',
                            subtitle: '点击修改密码',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () => _showEditDialog(
                                '新密码',
                                _passwordController,
                                (value) => _updateManagerInfo()),
                          ),
                          _buildListTile(
                            title: '联系电话',
                            subtitle: manager.contactNumber ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () => _showEditDialog(
                                '联系电话',
                                _contactNumberController,
                                (value) => _updateManagerInfo()),
                          ),
                          _buildListTile(
                            title: '邮箱',
                            subtitle: manager.email ?? '无数据',
                            themeData: themeData,
                            isLight: isLight,
                            onTap: () => _showEditDialog('邮箱', _emailController,
                                (value) => _updateManagerInfo()),
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
                            onTap: () => _showEditDialog(
                                '备注',
                                _remarksController,
                                (value) => _updateManagerInfo()),
                          ),
                          const SizedBox(height: 24.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: _updateManagerInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.colorScheme.primary,
                                foregroundColor:
                                    themeData.colorScheme.onPrimary,
                                elevation: 4,
                                shadowColor: themeData.colorScheme.shadow
                                    .withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: () => showCupertinoDialog(
                                context: context,
                                builder: (_) => CupertinoAlertDialog(
                                  title: const Text('登出'),
                                  content: const Text('确定要登出吗？'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('取消'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      onPressed: _logout,
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.colorScheme.error,
                                foregroundColor: themeData.colorScheme.onError,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0, vertical: 14.0),
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
