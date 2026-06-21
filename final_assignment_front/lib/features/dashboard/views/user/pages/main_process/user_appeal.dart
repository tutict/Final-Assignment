// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/realtime/business_event_listener.dart';
import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
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
import 'package:final_assignment_front/utils/widgets/index.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_business_page_chrome.dart';
import 'dart:developer' as developer;
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String getAppealProcessStatusLabel(String? status) {
  return AppealProcessStatus.fromCode(status)?.label ?? status ?? '未知';
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
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  final TextEditingController _searchController = TextEditingController();
  List<AppealRecordModel> _appeals = [];
  bool _isLoading = true;
  bool _isUser = false;
  String _errorMessage = '';
  late ScrollController _scrollController;
  List<dynamic> _offenseCache = [];
  int? _currentDriverId;
  String? _currentDriverName;
  StreamSubscription<AppealStatusChange>? _appealStatusSubscription;

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
    _startBusinessEventSubscription();
    _loadAppealsAndCheckRole();
  }

  @override
  void dispose() {
    _appealStatusSubscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startBusinessEventSubscription() async {
    if (!Get.isRegistered<BusinessEventListener>()) {
      return;
    }
    final listener = Get.find<BusinessEventListener>();
    try {
      await listener.startListening();
      _appealStatusSubscription ??=
          listener.appealStatusChanges.stream.listen(_handleAppealStatusChange);
    } catch (e) {
      developer.log('Failed to start appeal status listener: $e');
    }
  }

  void _handleAppealStatusChange(AppealStatusChange change) {
    if (!mounted || change.appealId == 0) {
      return;
    }
    final index =
        _appeals.indexWhere((appeal) => appeal.appealId == change.appealId);
    if (index == -1) {
      return;
    }
    setState(() {
      _appeals[index] = _appeals[index].copyWith(
        processStatus: change.newStatus,
        updatedAt: change.updatedAt,
      );
    });
    showUserBusinessToast(
      context,
      title: '申诉状态更新',
      message: '您的申诉已更新为 ${getAppealProcessStatusLabel(change.newStatus)}',
    );
  }

  Future<void> _loadAppealsAndCheckRole() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jwtToken = await AuthTokenStore.instance.getJwtToken();
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      if (JwtDecoder.isExpired(jwtToken)) {
        final refreshed = await Get.find<AuthService>().refreshJwtToken();
        jwtToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed || jwtToken == null || JwtDecoder.isExpired(jwtToken)) {
          throw Exception('登录已过期，请重新登录');
        }
      }
      await appealApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await userApi.initializeWithJwt();
      if (!Get.isRegistered<UserProfileService>()) {
        throw Exception('UserProfileService is not registered');
      }
      final profile = await Get.find<UserProfileService>().getProfile();
      _currentDriverId = profile.driverId;
      if (_currentDriverId == null) {
        throw Exception('Driver profile is not linked');
      }

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
        decoded = JwtDecoder.decode(jwtToken);
      } catch (e, stackTrace) {
        developer.log(
          'JWT decode failed',
          name: 'AuthError',
          error: e,
          stackTrace: stackTrace,
        );
        if (Get.isRegistered<AuthService>()) {
          await Get.find<AuthService>().clearTokens();
        } else {
          await AuthTokenStore.instance.clearAll();
        }
        NavigationHelper.offAllNamed(Routes.login);
        return null;
      }
      final username = storedUsername?.isNotEmpty == true
          ? storedUsername!
          : decoded['sub']?.toString();
      if (username == null || username.isEmpty) {
        throw Exception('无法确定当前用户');
      }
      if (!Get.isRegistered<UserProfileService>()) {
        throw Exception('UserProfileService is not registered');
      }
      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;
      _currentDriverId = driverId;
      if (driverId == null) {
        setState(() {
          _errorMessage = '您的账户尚未关联司机档案，请联系管理员';
        });
        return null;
      }

      await driverApi.initializeWithJwt();
      var driverInfo = await driverApi.getDriver(driverId: driverId);
      if (driverInfo == null) {
        driverInfo = DriverInformation(
          driverId: driverId,
          name: profile.driverName ?? profile.displayName ?? profile.username,
          contactNumber: profile.phoneNumber ?? '',
          idCardNumber: '',
          driverLicenseNumber:
              '${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString()}',
        );
        await driverApi.createDriver(
          driverInformation: driverInfo,
          idempotencyKey: generateIdempotencyKey(),
        );
        driverInfo = await driverApi.getDriver(driverId: driverId);
      }
      final driverName = driverInfo?.name ??
          profile.driverName ??
          profile.displayName ??
          profile.username;
      developer.log('Driver name from API: $driverName');
      return driverName;
    } catch (e) {
      developer.log('Error fetching driver name: $e');
      return null;
    }
  }

  Future<void> _checkUserOffenses() async {
    try {
      final driverId = _currentDriverId;
      if (driverId == null) {
        throw Exception('Driver profile is not linked');
      }
      if (_currentDriverName == null) {
        throw Exception('未找到驾驶员姓名');
      }
      final offenses = await offenseApi.listOffensesByDriver(
        driverId: driverId,
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
      final driverId = _currentDriverId;
      if (driverId == null) {
        throw Exception('Driver profile is not linked');
      }
      if (_currentDriverName == null) {
        throw Exception('未找到驾驶员姓名');
      }
      _offenseCache = await offenseApi.listOffensesByDriver(
        driverId: driverId,
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

  // ignore: unused_element
  Future<UserManagement?> _fetchUserManagement() async {
    try {
      await userApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        throw Exception('未找到用户名');
      }
      return await userApi.searchUsersByUsername(username: storedUsername);
    } catch (e) {
      developer.log('获取用户信息失败: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int driverId) async {
    try {
      return await driverApi.getDriver(driverId: driverId);
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

      final List<AppealRecordModel> fetched =
          await appealApi.listMyAppeals(page: 0, size: 50);
      final offenseIds =
          _offenseCache.map((o) => o['offenseId']).whereType<int>().toSet();
      if (offenseIds.isEmpty && fetched.isEmpty) {
        setState(() {
          _appeals = [];
          _isLoading = false;
          _errorMessage = '暂无申诉记录';
        });
        return;
      }
      final searchText = _searchController.text.trim().toLowerCase();
      final filtered = fetched.where((appeal) {
        final matchesName = appeal.appellantName == null ||
            appeal.appellantName == _currentDriverName;
        final matchesSearch = searchText.isEmpty
            ? true
            : (appeal.appealReason ?? '').toLowerCase().contains(searchText);
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
      await appealApi.createAppeal(
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
    final profile = await Get.find<UserProfileService>().getProfile();
    final int? driverId = profile.driverId ?? _currentDriverId;
    _currentDriverId = driverId;
    final driverInfo =
        driverId != null ? await _fetchDriverInformation(driverId) : null;
    final TextEditingController idCardController =
        TextEditingController(text: driverInfo?.idCardNumber ?? '');
    final TextEditingController contactController = TextEditingController(
        text: driverInfo?.contactNumber ?? profile.phoneNumber ?? '');
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
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
                child: Form(
                  key: formKey,
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
                          fillColor:
                              themeData.colorScheme.surfaceContainerLowest,
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
                        validator: (value) =>
                            value == null ? '请选择一个违法记录' : null,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
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
                                  size: 18,
                                  color: themeData.colorScheme.primary)
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入申诉人姓名';
                          }
                          return null;
                        },
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
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
                                  size: 18,
                                  color: themeData.colorScheme.primary)
                              : null,
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入身份证号';
                          }
                          final idRegex = RegExp(r'^\d{17}[\dXx]$');
                          if (!idRegex.hasMatch(value.trim())) {
                            return '请输入有效的 18 位身份证号';
                          }
                          return null;
                        },
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
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
                                  size: 18,
                                  color: themeData.colorScheme.primary)
                              : null,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入联系电话';
                          }
                          final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return '请输入有效的 11 位手机号';
                          }
                          return null;
                        },
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: '申诉原因 *',
                          labelStyle: TextStyle(
                              color: themeData.colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor:
                              themeData.colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: themeData.colorScheme.outline
                                    .withValues(alpha: 0.3)),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入申诉原因';
                          }
                          return null;
                        },
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
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
                                    final String name =
                                        nameController.text.trim();
                                    final String idCard =
                                        idCardController.text.trim();
                                    final String contact =
                                        contactController.text.trim();
                                    final String reason =
                                        reasonController.text.trim();

                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      setState(() => isSubmitting = false);
                                      return;
                                    }

                                    final newAppeal = AppealRecordModel(
                                      offenseId: selectedOffenseId,
                                      driverId: driverId,
                                      appellantName: name,
                                      appellantIdCard: idCard,
                                      appellantContact: contact,
                                      appealReason: reason,
                                      appealTime: DateTime.now(),
                                      acceptanceStatus:
                                          AppealAcceptanceStatus.pending.code,
                                      processStatus:
                                          AppealProcessStatus.unprocessed.code,
                                      processResult: '',
                                    );
                                    final idempotencyKey =
                                        generateIdempotencyKey();
                                    developer.log(
                                        'Preparing to submit appeal with key: $idempotencyKey');
                                    await _submitAppeal(
                                        newAppeal, idempotencyKey);
                                    setState(
                                        () => isSubmitting = false); // 重新启用按钮
                                    if (mounted) Navigator.pop(ctx);
                                  },
                            style:
                                themeData.elevatedButtonTheme.style?.copyWith(
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
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
    showUserBusinessToast(context, message: message, isError: isError);
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return SearchFilterBar(
      controller: _searchController,
      wrapInCard: true,
      cardElevation: 2,
      cardBorderRadius: 8,
      cardColor: themeData.colorScheme.surfaceContainer,
      cardPadding: const EdgeInsets.all(8),
      inputBorderRadius: 8,
      hintText: '搜索申诉原因',
      suggestions: _fetchAutocompleteSuggestions,
      showDateRange: true,
      startDate: _startTime,
      endDate: _endTime,
      dateRangeTextBuilder: (start, end) =>
          '日期范围: ${formatDateTime(start)} 至 ${formatDateTime(end)}',
      onDateRangeChanged: (range) {
        setState(() {
          _startTime = range?.start;
          _endTime = range?.end;
        });
        _fetchUserAppeals();
      },
      onSearch: (_) => _fetchUserAppeals(),
      onChanged: (value) {
        if (value.isEmpty) {
          _fetchUserAppeals(resetFilters: true);
        }
      },
      onClear: () {
        _searchController.clear();
        _fetchUserAppeals(resetFilters: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller?.currentBodyTheme.value ?? Theme.of(context);
      if (!_isUser) {
        return DashboardPageTemplate(
          theme: themeData,
          title: '用户申诉',
          pageType: DashboardPageType.user,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const UserBusinessPageHeader(
                  title: '用户申诉',
                  subtitle: '提交申诉材料，跟进审核状态和处理反馈。',
                  icon: Icons.gavel_rounded,
                  badge: '材料提交',
                  accentColor: Color(0xFFE5A33A),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: UserBusinessStatusPanel(
                    message: _errorMessage,
                    kind: UserBusinessStatusKind.error,
                    actionLabel: userBusinessMessageNeedsLogin(_errorMessage)
                        ? '重新登录'
                        : null,
                    onAction: userBusinessMessageNeedsLogin(_errorMessage)
                        ? () => NavigationHelper.offAllNamed(Routes.login)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return DashboardPageTemplate(
        theme: themeData,
        title: '用户申诉',
        pageType: DashboardPageType.user,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.add,
            tooltip: '提交申诉',
            onPressed: _showSubmitAppealDialog,
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              UserBusinessPageHeader(
                title: '用户申诉',
                subtitle: '提交申诉材料，跟进审核状态和处理反馈。',
                icon: Icons.gavel_rounded,
                badge: '${_appeals.length} 条申诉',
                accentColor: const Color(0xFFE5A33A),
              ),
              const SizedBox(height: 12),
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
                            child: UserBusinessStatusPanel(
                              message: _errorMessage,
                              kind: UserBusinessStatusKind.error,
                            ),
                          )
                        : _appeals.isEmpty
                            ? Center(
                                child: UserBusinessStatusPanel(
                                  message: _currentDriverName != null
                                      ? '暂无与申诉人 $_currentDriverName 匹配的申诉记录'
                                      : '未找到驾驶员信息，请重新登录',
                                  kind: _currentDriverName != null
                                      ? UserBusinessStatusKind.empty
                                      : UserBusinessStatusKind.error,
                                  actionLabel: _currentDriverName == null
                                      ? '重新登录'
                                      : null,
                                  onAction: _currentDriverName == null
                                      ? () => NavigationHelper.offAllNamed(
                                          Routes.login)
                                      : null,
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
                                    padding: EdgeInsets.zero,
                                    itemCount: _appeals.length,
                                    itemBuilder: (context, index) {
                                      final appeal = _appeals[index];
                                      return UserBusinessRecordCard(
                                        icon: Icons.gavel_rounded,
                                        title: appeal.appellantName ?? '未知申诉人',
                                        badge: getAppealProcessStatusLabel(
                                            appeal.processStatus),
                                        accentColor: const Color(0xFFE5A33A),
                                        details: [
                                          '申诉编号：${appeal.appealId ?? '无'}',
                                          '申诉原因：${appeal.appealReason ?? '无'}',
                                          '申诉时间：${formatDateTime(appeal.appealTime)}',
                                        ],
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
  late final ProgressController progressController;
  bool isLoading = false;

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    ProgressBinding.registerDependencies();
    progressController = Get.find<ProgressController>();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => isLoading = true);
    try {
      await progressController.fetchProgress();
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                          color: themeData.colorScheme.outline
                              .withValues(alpha: 0.3)),
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
                          color: themeData.colorScheme.outline
                              .withValues(alpha: 0.3)),
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
                  showUserBusinessToast(
                    context,
                    message: '标题不能为空',
                    isError: true,
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
                            getAppealProcessStatusLabel(
                                widget.appeal.processStatus),
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
                        isLoading
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
                                            onTap: () =>
                                                NavigationHelper.toNamed(
                                                    Routes.progressDetailPage,
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
