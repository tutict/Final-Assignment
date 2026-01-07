// ignore_for_file: use_build_context_synchronously
import 'dart:math';

import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/user/widgets/user_page_app_bar.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() =>
    DateTime.now().millisecondsSinceEpoch.toString();

String generateDriverLicenseNumber() {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final timestampPart = timestamp.substring(timestamp.length - 8);
  final randomPart = (1000 + Random().nextInt(9000)).toString();
  return timestampPart + randomPart;
}

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalMainPageState();
}

class _PersonalMainPageState extends State<PersonalMainPage> {
  final UserDashboardController dashboardController =
      Get.find<UserDashboardController>();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  final ApiClient apiClient = ApiClient();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  Future<UserManagement?>? _userFuture;
  DriverInformation? _driverInfo;
  bool _isLoading = true;
  bool _driverLicenseFinalized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    ever(dashboardController.refreshPersonalPage, (_) {
      if (dashboardController.refreshPersonalPage.value && mounted) {
        _loadCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _idCardController.dispose();
    _licenseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final storedUsername = prefs.getString('userName');
      if (jwtToken == null || storedUsername == null) {
        throw Exception('未登录，请重新登录');
      }
      await driverApi.initializeWithJwt();
      await userApi.initializeWithJwt();
      final user =
          await userApi.apiUsersSearchUsernameGet(username: storedUsername);
      if (user == null || user.userId == null) {
        throw Exception('加载用户信息失败');
      }
      final userId = user.userId!;
      DriverInformation? driverInfo =
          await driverApi.apiDriversDriverIdGet(driverId: userId);
      if (driverInfo == null) {
        final newDriver = DriverInformation(
          driverId: userId,
          name: user.username ?? '未知用户',
          contactNumber: user.contactNumber ?? '',
          idCardNumber: '',
          driverLicenseNumber: generateDriverLicenseNumber(),
        );
        await driverApi.apiDriversPost(
          driverInformation: newDriver,
          idempotencyKey: generateIdempotencyKey(),
        );
        driverInfo = await driverApi.apiDriversDriverIdGet(driverId: userId);
        _driverLicenseFinalized = true;
      } else {
        _driverLicenseFinalized =
            driverInfo.driverLicenseNumber?.isNotEmpty ?? false;
      }
      setState(() {
        _driverInfo = driverInfo;
        _userFuture = Future.value(user);
        _nameController.text = driverInfo?.name ?? user.username ?? '';
        _contactNumberController.text =
            driverInfo?.contactNumber ?? user.contactNumber ?? '';
        _idCardController.text = driverInfo?.idCardNumber ?? '';
        _licenseController.text = driverInfo?.driverLicenseNumber ?? '';
        _isLoading = false;
      });
      dashboardController.updateCurrentUser(
        driverInfo?.name ?? user.username ?? '',
        user.email ?? '',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
      });
    }
  }

  Future<void> _updateField(String field, String value) async {
    setState(() => _isLoading = true);
    try {
      final user = await _userFuture;
      if (user == null || user.userId == null) {
        throw Exception('未找到当前用户信息');
      }
      final userId = user.userId!;
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到登录凭证');

      switch (field) {
        case 'name':
        case 'contactNumber':
        case 'idCardNumber':
        case 'driverLicenseNumber':
          final updatedDriver = DriverInformation(
            driverId: userId,
            name: field == 'name'
                ? value
                : _driverInfo?.name ?? user.username ?? '未知用户',
            contactNumber: field == 'contactNumber'
                ? value
                : _driverInfo?.contactNumber ?? user.contactNumber ?? '',
            idCardNumber: field == 'idCardNumber'
                ? value
                : _driverInfo?.idCardNumber ?? '',
            driverLicenseNumber: field == 'driverLicenseNumber'
                ? value
                : _driverInfo?.driverLicenseNumber ?? '',
          );
          await driverApi.apiDriversPost(
            driverInformation: updatedDriver,
            idempotencyKey: idempotencyKey,
          );
          break;
        case 'password':
          await apiClient.invokeAPI(
            '/api/users/me/password?idempotencyKey=$idempotencyKey',
            'PUT',
            const [],
            value,
            {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'text/plain; charset=utf-8',
            },
            const {},
            'text/plain',
            const ['bearerAuth'],
          );
          break;
        default:
          throw Exception('未知字段: $field');
      }
      await _loadCurrentUser();
      AppSnackbar.showSuccess(context, message: '$field 更新成功');
    } catch (e) {
      AppSnackbar.showError(context, message: _formatErrorMessage(e));
      setState(() => _isLoading = false);
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      return '请求失败(${error.code}): ${error.message}';
    }
    return error.toString();
  }

  void _showEditDialog(
      String field, TextEditingController controller, VoidCallback onSave) {
    AppDialog.showCustomDialog(
      context: context,
      title: '编辑 $field',
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: '输入新的 $field',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: UserPageAppBar(
          theme: themeData,
          title: '个人信息管理',
          onThemeToggle: dashboardController.toggleBodyTheme,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: themeData.textTheme.bodyLarge?.copyWith(
                        color: themeData.colorScheme.error,
                      ),
                    ),
                  )
                : FutureBuilder<UserManagement?>(
                    future: _userFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final user = snapshot.data!;
                      return CupertinoScrollbar(
                        controller: _scrollController,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildEditableTile(
                              themeData,
                              title: '姓名',
                              value: _driverInfo?.name ?? '未填写',
                              onTap: () {
                                _nameController.text = _driverInfo?.name ?? '';
                                _showEditDialog('姓名', _nameController, () {
                                  _updateField('name', _nameController.text);
                                });
                              },
                            ),
                            _buildEditableTile(
                              themeData,
                              title: '联系电话',
                              value: _driverInfo?.contactNumber ??
                                  user.contactNumber ??
                                  '未填写',
                              onTap: () {
                                _contactNumberController.text =
                                    _driverInfo?.contactNumber ??
                                        user.contactNumber ??
                                        '';
                                _showEditDialog(
                                    '联系电话', _contactNumberController, () {
                                  _updateField('contactNumber',
                                      _contactNumberController.text);
                                });
                              },
                            ),
                            _buildEditableTile(
                              themeData,
                              title: '身份证号码',
                              value: _driverInfo?.idCardNumber ?? '未填写',
                              onTap: () {
                                _idCardController.text =
                                    _driverInfo?.idCardNumber ?? '';
                                _showEditDialog(
                                  '身份证号码',
                                  _idCardController,
                                  () => _updateField(
                                      'idCardNumber', _idCardController.text),
                                );
                              },
                            ),
                            _buildEditableTile(
                              themeData,
                              title: '驾驶证号',
                              value: _driverInfo?.driverLicenseNumber ?? '未填写',
                              onTap: _driverLicenseFinalized
                                  ? null
                                  : () {
                                      _licenseController.text =
                                          _driverInfo?.driverLicenseNumber ??
                                              '';
                                      _showEditDialog(
                                        '驾驶证号',
                                        _licenseController,
                                        () => _updateField(
                                            'driverLicenseNumber',
                                            _licenseController.text),
                                      );
                                    },
                            ),
                            _buildEditableTile(
                              themeData,
                              title: '密码',
                              value: '点击修改密码',
                              onTap: () {
                                _passwordController.clear();
                                _showEditDialog(
                                  '密码',
                                  _passwordController,
                                  () => _updateField(
                                      'password', _passwordController.text),
                                );
                              },
                            ),
                            _buildDisplayTile(
                              themeData,
                              title: '邮箱',
                              value: user.email ?? '未填写',
                            ),
                            _buildDisplayTile(
                              themeData,
                              title: '状态',
                              value: user.status ?? '未知',
                            ),
                            _buildDisplayTile(
                              themeData,
                              title: '创建时间',
                              value:
                                  user.createdTime?.toIso8601String() ?? '未知',
                            ),
                            _buildDisplayTile(
                              themeData,
                              title: '修改时间',
                              value:
                                  user.modifiedTime?.toIso8601String() ?? '未知',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      );
    });
  }

  Widget _buildEditableTile(
    ThemeData theme, {
    required String title,
    required String value,
    VoidCallback? onTap,
  }) =>
      Card(
        elevation: 2,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: onTap != null
              ? Icon(Icons.edit, color: theme.colorScheme.primary)
              : null,
          onTap: onTap,
        ),
      );

  Widget _buildDisplayTile(
    ThemeData theme, {
    required String title,
    required String value,
  }) =>
      Card(
        elevation: 2,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}
