import 'dart:convert';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalMainPage> {
  late Future<UserManagement?> _userFuture;
  DriverInformation? _driverInfo;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final ApiClient apiClient = ApiClient();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  bool _isLoading = true;
  final bool _isEditable = true;
  bool _idCardNumberEdited = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _userFuture = Future.value(null);
    _loadCurrentUser();
    ever(controller.refreshPersonalPage, (_) {
      if (controller.refreshPersonalPage.value && mounted) {
        debugPrint('Refresh triggered from UserDashboardController');
        _loadCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _idCardNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      debugPrint('JWT Token: $jwtToken');
      if (jwtToken == null) {
        throw Exception('JWT Token not found in SharedPreferences');
      }

      await driverApi.initializeWithJwt();
      debugPrint('Driver API initialized with JWT');

      final response = await apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        {'Authorization': 'Bearer $jwtToken'},
        {},
        'application/json',
        ['bearerAuth'],
      );
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode,
            '加载用户信息失败: ${utf8.decode(response.bodyBytes)}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint('User data: $data');
      final user = UserManagement.fromJson(data);

      DriverInformation? driverInfo;
      if (user.userId != null) {
        try {
          driverInfo =
              await driverApi.apiDriversDriverIdGet(driverId: user.userId);
          debugPrint('Driver info fetched: ${driverInfo?.toJson()}');
          if (driverInfo?.idCardNumber != null &&
              driverInfo!.idCardNumber!.isNotEmpty) {
            _idCardNumberEdited = true;
          }
        } catch (e) {
          if (e is ApiException && e.code == 404) {
            final idempotencyKey = generateIdempotencyKey();
            driverInfo = DriverInformation(
              driverId: user.userId,
              name: user.username ?? '未知用户',
              contactNumber: user.contactNumber ?? '',
              idCardNumber: '',
            );
            debugPrint(
                'Creating new driver with driverId: ${user.userId}, name: ${user.username}');
            await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: idempotencyKey,
            );
            driverInfo =
                await driverApi.apiDriversDriverIdGet(driverId: user.userId);
            debugPrint('Driver created and fetched: ${driverInfo?.toJson()}');
          } else {
            debugPrint('Driver fetch error: $e');
            if (mounted) setState(() => _errorMessage = _formatErrorMessage(e));
            rethrow;
          }
        }
        _driverInfo = driverInfo;
      } else {
        throw Exception('用户ID为空，无法加载或创建司机信息');
      }

      if (mounted) {
        setState(() {
          _userFuture = Future.value(user);
          _nameController.text = driverInfo?.name ?? '';
          _usernameController.text = user.username ?? '';
          _passwordController.text = '';
          _contactNumberController.text =
              driverInfo?.contactNumber ?? user.contactNumber ?? '';
          _emailController.text = user.email ?? '';
          _idCardNumberController.text = driverInfo?.idCardNumber ?? '';
          _isLoading = false;
        });
      }
      controller.updateCurrentUser(driverInfo?.name ?? '', user.username ?? '');
    } catch (e) {
      debugPrint('Load current user error: $e');
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
      final currentUser = await _userFuture;
      if (currentUser == null) throw Exception('未找到当前用户信息');
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('JWT Token not found');

      switch (field) {
        case 'name':
          final newDriverName = DriverInformation(
            driverId: currentUser.userId,
            name: value,
            contactNumber:
                _driverInfo?.contactNumber ?? currentUser.contactNumber ?? '',
            idCardNumber: _driverInfo?.idCardNumber ?? '',
          );
          debugPrint(
              'Updating driver with driverId: ${currentUser.userId}, name: $value');
          await driverApi.apiDriversPost(
            driverInformation: newDriverName,
            idempotencyKey: idempotencyKey,
          );
          _driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: currentUser.userId);
          debugPrint('Driver updated and fetched: ${_driverInfo?.toJson()}');
          break;

        case 'contactNumber':
          final newDriverContact = DriverInformation(
            driverId: currentUser.userId,
            name: _driverInfo?.name ?? currentUser.username ?? '未知用户',
            contactNumber: value,
            idCardNumber: _driverInfo?.idCardNumber ?? '',
          );
          debugPrint(
              'Updating driver with driverId: ${currentUser.userId}, contactNumber: $value');
          await driverApi.apiDriversPost(
            driverInformation: newDriverContact,
            idempotencyKey: idempotencyKey,
          );
          _driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: currentUser.userId);
          debugPrint('Driver updated and fetched: ${_driverInfo?.toJson()}');
          break;

        case 'idCardNumber':
          final newDriverIdCard = DriverInformation(
            driverId: currentUser.userId,
            name: _driverInfo?.name ?? currentUser.username ?? '未知用户',
            contactNumber:
                _driverInfo?.contactNumber ?? currentUser.contactNumber ?? '',
            idCardNumber: value,
          );
          debugPrint(
              'Updating driver with driverId: ${currentUser.userId}, idCardNumber: $value');
          await driverApi.apiDriversPost(
            driverInformation: newDriverIdCard,
            idempotencyKey: idempotencyKey,
          );
          _driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: currentUser.userId);
          debugPrint('Driver updated and fetched: ${_driverInfo?.toJson()}');
          if (mounted) setState(() => _idCardNumberEdited = true);
          break;

        case 'password':
          await apiClient.invokeAPI(
            '/api/users/me/password?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'text/plain; charset=utf-8'
            },
            {},
            'text/plain',
            ['bearerAuth'],
          );
          break;

        case 'status':
          await apiClient.invokeAPI(
            '/api/users/me/status?idempotencyKey=$idempotencyKey',
            'PUT',
            [],
            value,
            {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'text/plain; charset=utf-8'
            },
            {},
            'text/plain',
            ['bearerAuth'],
          );
          break;

        default:
          throw Exception('未知字段: $field');
      }

      await _loadCurrentUser();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$field 更新成功！',
                style: TextStyle(
                    color: controller.currentBodyTheme.value.colorScheme
                        .onPrimaryContainer)),
            backgroundColor:
                controller.currentBodyTheme.value.colorScheme.primary,
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

  void _showEditDialog(String field, TextEditingController textController,
      void Function(String) onSave) {
    final themeData = controller.currentBodyTheme.value;
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
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '用户信息管理',
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
            child: Text(
              _errorMessage.isNotEmpty ? _errorMessage : '未找到用户信息',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.error,
                fontSize: 18,
              ),
            ),
          );
        } else {
          final userInfo = snapshot.data!;
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
                  onTap: _isEditable
                      ? () {
                          _nameController.text = _driverInfo?.name ?? '';
                          _showEditDialog('姓名', _nameController,
                              (value) => _updateField('name', value));
                        }
                      : null,
                ),
                _buildListTile(
                  title: '邮箱',
                  subtitle: userInfo.username ?? '无数据',
                  themeData: themeData,
                ),
                _buildListTile(
                  title: '密码',
                  subtitle: '点击修改密码',
                  themeData: themeData,
                  onTap: _isEditable
                      ? () {
                          _passwordController.clear();
                          _showEditDialog('密码', _passwordController,
                              (value) => _updateField('password', value));
                        }
                      : null,
                ),
                _buildListTile(
                  title: '联系电话',
                  subtitle: _driverInfo?.contactNumber ??
                      userInfo.contactNumber ??
                      '无数据',
                  themeData: themeData,
                  onTap: _isEditable
                      ? () {
                          _contactNumberController.text =
                              _driverInfo?.contactNumber ??
                                  userInfo.contactNumber ??
                                  '';
                          _showEditDialog('联系电话', _contactNumberController,
                              (value) => _updateField('contactNumber', value));
                        }
                      : null,
                ),
                _buildListTile(
                  title: '身份证号码',
                  subtitle: _driverInfo?.idCardNumber ?? '无数据',
                  themeData: themeData,
                  onTap: _isEditable && !_idCardNumberEdited
                      ? () {
                          _idCardNumberController.text =
                              _driverInfo?.idCardNumber ?? '';
                          _showEditDialog('身份证号码', _idCardNumberController,
                              (value) => _updateField('idCardNumber', value));
                        }
                      : null,
                ),
                _buildListTile(
                  title: '状态',
                  subtitle: userInfo.status ?? '无数据',
                  themeData: themeData,
                  onTap: _isEditable
                      ? () {
                          _showEditDialog(
                              '状态',
                              TextEditingController(
                                  text: userInfo.status ?? ''),
                              (value) => _updateField('status', value));
                        }
                      : null,
                ),
                _buildListTile(
                  title: '创建时间',
                  subtitle: userInfo.createdTime?.toString() ?? '无数据',
                  themeData: themeData,
                ),
                _buildListTile(
                  title: '修改时间',
                  subtitle: userInfo.modifiedTime?.toString() ?? '无数据',
                  themeData: themeData,
                ),
                _buildListTile(
                  title: '备注',
                  subtitle: userInfo.remarks ?? '无数据',
                  themeData: themeData,
                  onTap: _isEditable
                      ? () {
                          _showEditDialog(
                              '备注',
                              TextEditingController(
                                  text: userInfo.remarks ?? ''), (value) {
                            userInfo.remarks = value;
                            _loadCurrentUser();
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          );
        }
      },
    );
  }
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
      trailing: onTap != null
          ? Icon(Icons.edit, color: themeData.colorScheme.primary)
          : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    ),
  );
}
