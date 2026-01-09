// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'dart:developer' as developer;

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

class _UserAppealPageState extends State<UserAppealPage> {
  late AppealManagementControllerApi appealApi;
  late DriverInformationControllerApi driverApi;
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
  final TextEditingController _searchController = TextEditingController();
  List<AppealRecordModel> _appeals = [];
  bool _isLoading = true;
  bool _isUser = false;
  String _errorMessage = '';
  late ScrollController _scrollController;
  List<dynamic> _offenseCache = [];
  String? _currentDriverName;

  DateTime? _startTime;
  DateTime? _endTime;

  final UserDashboardController? controller =
  Get.isRegistered<UserDashboardController>()
      ? Get.find<UserDashboardController>()
      : null;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    driverApi = DriverInformationControllerApi();
    _scrollController = ScrollController();
    _loadAppealsAndCheckRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAppealsAndCheckRole() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      await appealApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await userApi.initializeWithJwt();

      _currentDriverName = prefs.getString('driverName');
      if (_currentDriverName == null) {
        _currentDriverName = await _fetchDriverName(jwtToken);
        if (_currentDriverName == null) {
          throw Exception('无法获取驾驶员姓名，请重新登录');
        }
        await prefs.setString('driverName', _currentDriverName!);
        developer.log('Fetched and stored driver name: $_currentDriverName');
      }
      developer.log('Current Driver Name: $_currentDriverName');

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      _isUser = roles.contains('USER');
      if (!_isUser) {
        throw Exception('权限不足：仅用户可访问此页面');
      }

      await _checkUserOffenses();
      await _fetchUserAppeals();
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
      if (parts.length != 3) throw Exception('无效的JWT格式');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      developer.log('JWT解码错误: $e');
      return {};
    }
  }

  Future<String?> _fetchDriverName(String jwtToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      Map<String, dynamic>? decoded;
      try {
        decoded = _decodeJwt(jwtToken);
      } catch (_) {}
      final username = storedUsername?.isNotEmpty == true
          ? storedUsername!
          : decoded?['sub']?.toString();
      if (username == null || username.isEmpty) {
        throw Exception('无法确定当前用户');
      }
      await userApi.initializeWithJwt();
      final userData =
          await userApi.apiUsersSearchUsernameGet(username: username);
      if (userData == null || userData.userId == null) {
        throw Exception('User data does not contain userId');
      }
      final int userId = userData.userId!;

      await driverApi.initializeWithJwt();
      var driverInfo =
          await driverApi.apiDriversDriverIdGet(driverId: userId);
      if (driverInfo == null) {
        driverInfo = DriverInformation(
          driverId: userId,
          name: userData.username ?? '未知用户',
          contactNumber: userData.contactNumber ?? '',
          idCardNumber: '',
          driverLicenseNumber:
              '${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString()}',
        );
        await driverApi.apiDriversPost(
          driverInformation: driverInfo,
          idempotencyKey: generateIdempotencyKey(),
        );
        driverInfo =
            await driverApi.apiDriversDriverIdGet(driverId: userId);
      }
      final driverName = driverInfo?.name ?? userData.username ?? '未知用户';
      developer.log('Driver name from API: $driverName');
      return driverName;
    } catch (e) {
      developer.log('Error fetching driver name: $e');
      return null;
    }
  }

  Future<void> _checkUserOffenses() async {
    try {
      if (_currentDriverName == null) {
        throw Exception('未找到驾驶员姓名');
      }
      final offenses = await offenseApi.apiOffensesByDriverNameGet(
        query: _currentDriverName!,
        page: 1,
        size: 20,
      );
      developer.log('Fetched offenses: ${offenses.length}');
      setState(() {
        _offenseCache = offenses.map((o) => o.toJson()).toList();
      });
    } catch (e) {
      developer.log('Error checking user offenses: $e');
      setState(() {
        _errorMessage = '无法检查违法信息: $e';
      });
    }
  }

  Future<List<dynamic>> _fetchUserOffenses() async {
    try {
      if (_currentDriverName == null) {
        throw Exception('未找到驾驶员姓名');
      }
      _offenseCache = await offenseApi.apiOffensesByDriverNameGet(
        query: _currentDriverName!,
        page: 1,
        size: 20,
      );
      developer.log('Fetched offenses for dialog: $_offenseCache');
      return _offenseCache.map((o) => o.toJson()).toList();
    } catch (e) {
      developer.log('Error fetching user offenses: $e');
      return [];
    }
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      await userApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        throw Exception('未找到用户名');
      }
      return await userApi.apiUsersSearchUsernameGet(
          username: storedUsername);
    } catch (e) {
      developer.log('获取用户信息失败: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      return await driverApi.apiDriversDriverIdGet(driverId: userId);
    } catch (e) {
      developer.log('获取驾驶员信息失败: $e');
      return null;
    }
  }

  Future<void> _fetchUserAppeals({bool resetFilters = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (_currentDriverName == null) {
        throw Exception('未找到驾驶员姓名');
      }

      if (resetFilters) {
        _startTime = null;
        _endTime = null;
        _searchController.clear();
      }

      final offenseIds = _offenseCache
          .map((o) => o['offenseId'])
          .whereType<int>()
          .toSet();
      if (offenseIds.isEmpty) {
        setState(() {
          _appeals = [];
          _isLoading = false;
          _errorMessage = '暂无申诉记录';
        });
        return;
      }
      final List<AppealRecordModel> fetched = [];
      for (final id in offenseIds) {
        try {
          final records =
              await appealApi.apiAppealsGet(offenseId: id, page: 1, size: 50);
          fetched.addAll(records);
        } catch (e) {
          developer
              .log('Failed to fetch appeals for offense $id: $e');
        }
      }

      final searchText = _searchController.text.trim().toLowerCase();
      final filtered = fetched.where((appeal) {
        final matchesName =
            appeal.appellantName == null || appeal.appellantName == _currentDriverName;
        final matchesSearch = searchText.isEmpty
            ? true
            : (appeal.appealReason ?? '')
                .toLowerCase()
                .contains(searchText);
        bool matchesRange = true;
        if (_startTime != null && _endTime != null) {
          final time = appeal.appealTime;
          matchesRange = time != null &&
              !time.isBefore(_startTime!) &&
              !time.isAfter(_endTime!);
        }
        return matchesName && matchesSearch && matchesRange;
      }).toList();

      setState(() {
        _appeals = filtered;
        _isLoading = false;
        if (_appeals.isEmpty) {
          _errorMessage = _searchController.text.isNotEmpty ||
              (_startTime != null && _endTime != null)
              ? '未找到符合条件的申诉记录'
              : '暂无申诉记录';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉记录失败: $e';
      });
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    final lowerPrefix = prefix.toLowerCase();
    return _appeals
        .map((appeal) => appeal.appealReason ?? '')
        .where((reason) => reason.toLowerCase().contains(lowerPrefix))
        .toList();
  }

  Future<void> _submitAppeal(
      AppealRecordModel appeal, String idempotencyKey) async {
    try {
      developer.log('Submitting appeal with idempotencyKey: $idempotencyKey');
      await appealApi.apiAppealsPost(
          appealRecord: appeal, idempotencyKey: idempotencyKey);
      developer.log('Appeal submitted successfully: ${appeal.toJson()}');
      _showSnackBar('申诉提交成功！');
      await _fetchUserAppeals();
    } catch (e) {
      developer.log('Appeal submission failed: $e');
      _showSnackBar('申诉提交失败: $e', isError: true);
    }
  }

  void _showSubmitAppealDialog() async {
    final TextEditingController nameController =
    TextEditingController(text: _currentDriverName ?? '');
    final user = await _fetchUserManagement();
    final int? userId = user?.userId;
    final driverInfo =
        userId != null ? await _fetchDriverInformation(userId) : null;
    final TextEditingController idCardController =
    TextEditingController(text: driverInfo?.idCardNumber ?? '');
    final TextEditingController contactController = TextEditingController(
        text: driverInfo?.contactNumber ?? user?.contactNumber ?? '');
    final TextEditingController reasonController = TextEditingController();
    int? selectedOffenseId;
    bool isSubmitting = false; // 新增：防止重复提交

    final bool isNameReadOnly = nameController.text.isNotEmpty;
    final bool isIdCardReadOnly = idCardController.text.isNotEmpty;
    final bool isContactReadOnly = contactController.text.isNotEmpty;

    final offenses = await _fetchUserOffenses();
    if (offenses.isEmpty) {
      _showSnackBar('您当前没有违法记录，无法提交申诉', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Obx(() {
        final themeData =
            controller?.currentBodyTheme.value ?? Theme.of(context);
        return Dialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(maxWidth: 300.0, minHeight: 200.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '提交申诉',
                      style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: '选择违法记录 *',
                        labelStyle: TextStyle(
                            color: themeData.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                      items: offenses.map((offense) {
                        return DropdownMenuItem<int>(
                          value: offense['offenseId'],
                          child: Text(
                              'ID: ${offense['offenseId']} - ${offense['offenseType'] ?? '无描述'}'),
                        );
                      }).toList(),
                      onChanged: (value) => selectedOffenseId = value,
                      validator: (value) => value == null ? '请选择一个违法记录' : null,
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: nameController,
                      readOnly: isNameReadOnly,
                      decoration: InputDecoration(
                        labelText: '申诉人姓名 *',
                        labelStyle: TextStyle(
                            color: themeData.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: isNameReadOnly
                            ? themeData.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                            : themeData.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                        suffixIcon: isNameReadOnly
                            ? Icon(Icons.lock,
                            size: 18, color: themeData.colorScheme.primary)
                            : null,
                      ),
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: idCardController,
                      readOnly: isIdCardReadOnly,
                      decoration: InputDecoration(
                        labelText: '身份证号码 *',
                        labelStyle: TextStyle(
                            color: themeData.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: isIdCardReadOnly
                            ? themeData.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                            : themeData.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                        suffixIcon: isIdCardReadOnly
                            ? Icon(Icons.lock,
                            size: 18, color: themeData.colorScheme.primary)
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: contactController,
                      readOnly: isContactReadOnly,
                      decoration: InputDecoration(
                        labelText: '联系电话 *',
                        labelStyle: TextStyle(
                            color: themeData.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: isContactReadOnly
                            ? themeData.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                            : themeData.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                        suffixIcon: isContactReadOnly
                            ? Icon(Icons.lock,
                            size: 18, color: themeData.colorScheme.primary)
                            : null,
                      ),
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: '申诉原因 *',
                        labelStyle: TextStyle(
                            color: themeData.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                      maxLines: 3,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            '取消',
                            style: themeData.textTheme.labelMedium?.copyWith(
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            setState(() => isSubmitting = true); // 禁用按钮
                            final String name = nameController.text.trim();
                            final String idCard = idCardController.text.trim();
                            final String contact =
                            contactController.text.trim();
                            final String reason = reasonController.text.trim();

                            if (selectedOffenseId == null ||
                                name.isEmpty ||
                                idCard.isEmpty ||
                                contact.isEmpty ||
                                reason.isEmpty) {
                              _showSnackBar('请填写所有必填字段', isError: true);
                              setState(() => isSubmitting = false);
                              return;
                            }
                            // final RegExp idCardRegExp =
                            //     RegExp(r'^\d{15}$|^\d{17}[\dXx]$');
                            // final RegExp contactRegExp = RegExp(r'^\d{10,15}$');

                            // if (!idCardRegExp.hasMatch(idCard)) {
                            //   _showSnackBar('身份证号码格式不正确', isError: true);
                            //   setState(() => isSubmitting = false);
                            //   return;
                            // }
                            // if (!contactRegExp.hasMatch(contact)) {
                            //   _showSnackBar('联系电话格式不正确', isError: true);
                            //   setState(() => isSubmitting = false);
                            //   return;
                            // }

                            final newAppeal = AppealRecordModel(
                              offenseId: selectedOffenseId,
                              appellantName: name,
                              appellantIdCard: idCard,
                              appellantContact: contact,
                              appealReason: reason,
                              appealTime: DateTime.now(),
                              processStatus: 'Pending',
                              processResult: '',
                            );
                            final idempotencyKey = generateIdempotencyKey();
                            developer.log('Preparing to submit appeal with key: $idempotencyKey');
                            await _submitAppeal(newAppeal, idempotencyKey);
                            setState(() => isSubmitting = false); // 重新启用按钮
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: themeData.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(
                                themeData.colorScheme.primary),
                            foregroundColor: WidgetStateProperty.all(
                                themeData.colorScheme.onPrimary),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text('提交'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ).whenComplete(() {
      nameController.dispose();
      idCardController.dispose();
      contactController.dispose();
      reasonController.dispose();
      setState(() => isSubmitting = false); // 确保关闭对话框后重置状态
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 2,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return await _fetchAutocompleteSuggestions(
                          textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _searchController.text = selection;
                      _fetchUserAppeals();
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      _searchController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style:
                        TextStyle(color: themeData.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: '搜索申诉原因',
                          hintStyle: TextStyle(
                              color: themeData.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search,
                              color: themeData.colorScheme.primary),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData
                                    .colorScheme.onSurfaceVariant),
                            onPressed: () {
                              controller.clear();
                              _searchController.clear();
                              _fetchUserAppeals(resetFilters: true);
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: themeData.colorScheme.outline
                                    .withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: themeData.colorScheme.primary,
                                width: 1.5),
                          ),
                          filled: true,
                          fillColor:
                          themeData.colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _fetchUserAppeals(resetFilters: true);
                          }
                        },
                        onSubmitted: (value) => _fetchUserAppeals(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startTime != null && _endTime != null
                        ? '日期范围: ${formatDateTime(_startTime)} 至 ${formatDateTime(_endTime)}'
                        : '选择日期范围',
                    style: TextStyle(
                      color: _startTime != null && _endTime != null
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range,
                      color: themeData.colorScheme.primary),
                  tooltip: '按日期范围搜索',
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('zh', 'CN'),
                      helpText: '选择日期范围',
                      cancelText: '取消',
                      confirmText: '确定',
                      fieldStartHintText: '开始日期',
                      fieldEndHintText: '结束日期',
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _startTime = range.start;
                        _endTime = range.end;
                      });
                      _fetchUserAppeals();
                    }
                  },
                ),
                if (_startTime != null && _endTime != null)
                  IconButton(
                    icon: Icon(Icons.clear,
                        color: themeData.colorScheme.onSurfaceVariant),
                    tooltip: '清除日期范围',
                    onPressed: () {
                      setState(() {
                        _startTime = null;
                        _endTime = null;
                      });
                      _fetchUserAppeals();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller?.currentBodyTheme.value ?? Theme.of(context);
      if (!_isUser) {
        return DashboardPageTemplate(
          theme: themeData,
          title: '用户申诉管理',
          pageType: DashboardPageType.custom,
          body: Center(
            child: Text(
              _errorMessage,
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.error,
              ),
            ),
          ),
        );
      }

      return DashboardPageTemplate(
        theme: themeData,
        title: '用户申诉管理',
        pageType: DashboardPageType.user,
        onThemeToggle: controller?.toggleBodyTheme,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        floatingActionButton: FloatingActionButton(
          onPressed: _showSubmitAppealDialog,
          backgroundColor: themeData.colorScheme.primary,
          foregroundColor: themeData.colorScheme.onPrimary,
          tooltip: '提交申诉',
          child: const Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(themeData),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              themeData.colorScheme.primary),
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: themeData.textTheme.bodyLarge?.copyWith(
                                color: themeData.colorScheme.error,
                              ),
                            ),
                          )
                        : _appeals.isEmpty
                            ? Center(
                                child: Text(
                                  _currentDriverName != null
                                      ? '暂无与申诉人 $_currentDriverName 匹配的申诉记录'
                                      : '未找到驾驶员信息，请重新登录',
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color:
                                        themeData.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : CupertinoScrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: RefreshIndicator(
                                  onRefresh: () => _fetchUserAppeals(),
                                  color: themeData.colorScheme.primary,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _appeals.length,
                                    itemBuilder: (context, index) {
                                      final appeal = _appeals[index];
                                      return Card(
                                        elevation: 3,
                                        color: themeData
                                            .colorScheme.surfaceContainer,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0)),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6.0),
                                        child: ListTile(
                                          title: Text(
                                            '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                                            style: themeData.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus == "Pending" ? "待处理" : appeal.processStatus == "Approved" ? "已通过" : "已拒绝"}\n时间: ${formatDateTime(appeal.appealTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserAppealDetailPage(
                                                        appeal: appeal),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class UserAppealDetailPage extends StatefulWidget {
  final AppealRecordModel appeal;

  const UserAppealDetailPage({super.key, required this.appeal});

  @override
  State<UserAppealDetailPage> createState() => _UserAppealDetailPageState();
}

class _UserAppealDetailPageState extends State<UserAppealDetailPage> {
  final ProgressController progressController = Get.find<ProgressController>();
  bool _isLoadingProgress = false;

  final UserDashboardController? controller =
  Get.isRegistered<UserDashboardController>()
      ? Get.find<UserDashboardController>()
      : null;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => _isLoadingProgress = true);
    try {
      await progressController.fetchProgress();
    } finally {
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitProgressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Obx(() {
        final themeData =
            controller?.currentBodyTheme.value ?? Theme.of(context);
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          title: Text(
            '提交反馈',
            style: themeData.textTheme.titleLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: '反馈内容标题',
                    labelStyle: TextStyle(
                        color: themeData.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                          themeData.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: '详情（可选）',
                    labelStyle: TextStyle(
                        color: themeData.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                          themeData.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 1.5),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('标题不能为空'),
                      backgroundColor: themeData.colorScheme.error,
                    ),
                  );
                  return;
                }
                await progressController.submitProgress(
                  titleController.text,
                  detailsController.text.isNotEmpty
                      ? detailsController.text
                      : null,
                  appealId: widget.appeal.appealId,
                );
                Navigator.pop(ctx);
                _fetchProgress();
              },
              style: themeData.elevatedButtonTheme.style?.copyWith(
                backgroundColor:
                WidgetStateProperty.all(themeData.colorScheme.primary),
                foregroundColor:
                WidgetStateProperty.all(themeData.colorScheme.onPrimary),
              ),
              child: const Text('提交'),
            ),
          ],
        );
      }),
    ).whenComplete(() {
      titleController.dispose();
      detailsController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller?.currentBodyTheme.value ?? Theme.of(context);
      return DashboardPageTemplate(
        theme: themeData,
        title: '申诉详情',
        pageType: DashboardPageType.user,
        onThemeToggle: controller?.toggleBodyTheme,
        onRefresh: _fetchProgress,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        floatingActionButton: FloatingActionButton(
          onPressed: _showSubmitProgressDialog,
          backgroundColor: themeData.colorScheme.primary,
          foregroundColor: themeData.colorScheme.onPrimary,
          tooltip: '提交反馈',
          child: const Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CupertinoScrollbar(
            thumbVisibility: true,
            child: ListView(
              children: [
                Card(
                  elevation: 2,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            '申诉ID',
                            widget.appeal.appealId?.toString() ?? '无',
                            themeData),
                        _buildDetailRow(
                            '违法ID',
                            widget.appeal.offenseId?.toString() ?? '无',
                            themeData),
                        _buildDetailRow('上诉人',
                            widget.appeal.appellantName ?? '无', themeData),
                        _buildDetailRow('身份证号码',
                            widget.appeal.appellantIdCard ?? '无', themeData),
                        _buildDetailRow('联系电话',
                            widget.appeal.appellantContact ?? '无', themeData),
                        _buildDetailRow('申诉原因',
                            widget.appeal.appealReason ?? '无', themeData),
                        _buildDetailRow(
                            '申诉时间',
                            formatDateTime(widget.appeal.appealTime),
                            themeData),
                        _buildDetailRow(
                            '处理状态',
                            widget.appeal.processStatus == "Pending"
                                ? "待处理"
                                : widget.appeal.processStatus == "Approved"
                                    ? "已通过"
                                    : "已拒绝",
                            themeData),
                        _buildDetailRow('处理结果',
                            widget.appeal.processResult ?? '无', themeData),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '相关反馈',
                          style: themeData.textTheme.titleLarge?.copyWith(
                            color: themeData.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingProgress
                            ? const Center(child: CircularProgressIndicator())
                            : Obx(() {
                                final relatedProgress = progressController
                                    .progressItems
                                    .where((p) =>
                                        p.appealId == widget.appeal.appealId)
                                    .toList();
                                if (relatedProgress.isEmpty) {
                                  return Text(
                                    '暂无相关反馈记录',
                                    style: themeData.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                }
                                return Column(
                                  children: relatedProgress
                                      .map((item) => ListTile(
                                            title: Text(
                                              item.title,
                                              style:
                                                  themeData.textTheme.bodyLarge,
                                            ),
                                            subtitle: Text(
                                              '状态: ${item.status}\n提交时间: ${formatDateTime(item.submitTime)}',
                                              style: themeData
                                                  .textTheme.bodyMedium,
                                            ),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios),
                                            onTap: () => Get.toNamed(
                                                '/progressDetail',
                                                arguments: item),
                                          ))
                                      .toList(),
                                );
                              }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '注意：用户无法修改或删除申诉，请联系管理员进行操作。',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
