// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/config/app_config.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/shared/widgets/index.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/workflow_permissions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

String generateIdempotencyKey() {
  return const Uuid().v4();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}

String getDisplayStatus(String? status) {
  final processStatus = AppealProcessStatus.fromCode(status);
  return processStatus?.label ?? status ?? '未知';
}

Color getAppealProcessStatusColor(String? status, ThemeData themeData) {
  return AppealProcessStatus.fromCode(status)?.color ??
      themeData.colorScheme.onSurfaceVariant;
}

class ManagerAppealManagementPage extends StatefulWidget {
  const ManagerAppealManagementPage({super.key});

  @override
  State<ManagerAppealManagementPage> createState() =>
      _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<ManagerAppealManagementPage> {
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  List<AppealRecordModel> _appeals = [];
  List<AppealRecordModel> _filteredAppeals = [];
  String _searchType = 'appealReason';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  static const int _maxOffenseBatch = 20;
  final ManagerDashboardController controller =
      Get.find<ManagerDashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      _applyFilters(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权：未找到登录信息，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer.log('JWT token validated successfully for appeal request');
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息：$e，请重新登录');
      developer.log('JWT validation failed: $e',
          stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        developer.log('JWT token refreshed successfully');
        return newJwt;
      }
      developer.log(
          'Refresh token request failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      developer.log('Error refreshing JWT token: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      await appealApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) {
        await _loadAppeals(reset: true);
      } else {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
      }
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
      developer.log('Initialization failed: $e',
          stackTrace: StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/users/me'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          developer.log('User data from /api/users/me: $userData');
          final roles = (userData['roles'] as List<dynamic>?)
              ?.map((r) => r.toString().toUpperCase())
              .toList();
          if (roles != null && roles.contains('ADMIN')) {
            setState(() => _isAdmin = true);
            return;
          }
          developer.log(
              'No valid roles in /api/users/me response, falling back to JWT');
        } else {
          developer.log(
              'Failed to fetch user roles: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        developer.log('Error fetching user roles from API: $e');
      }

      // Fallback to JWTSwe token roles
      await _checkRolesFromJwt();
    } catch (e) {
      setState(() => _errorMessage = '验证角色失败: $e');
      developer.log('Role check failed: $e', stackTrace: StackTrace.current);
    }
  }

  Future<void> _checkRolesFromJwt() async {
    try {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      developer.log('JWT decoded: $decodedToken');
      final rawRoles = decodedToken['roles'];
      List<String> roles;
      if (rawRoles is String) {
        roles = rawRoles
            .split(',')
            .map((role) => role.trim().toUpperCase())
            .toList();
      } else if (rawRoles is List<dynamic>) {
        roles = rawRoles.map((role) => role.toString().toUpperCase()).toList();
      } else {
        roles = [];
      }
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：JWT角色为 $roles，非管理员');
      }
      developer.log('Roles from JWT: $roles, isAdmin: $_isAdmin');
    } catch (e) {
      setState(() => _errorMessage = '从JWT验证角色失败: $e');
      developer.log('JWT role check failed: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    if (prefix.isEmpty) return [];
    final normalized = prefix.toLowerCase();
    Iterable<String> values = const Iterable.empty();
    switch (_searchType) {
      case 'appealReason':
        values = _appeals.map((appeal) => appeal.appealReason ?? '');
        break;
      case 'appellantName':
        values = _appeals.map((appeal) => appeal.appellantName ?? '');
        break;
      case 'processStatus':
        values =
            _appeals.map((appeal) => getDisplayStatus(appeal.processStatus));
        break;
      default:
        return [];
    }
    return values
        .where((value) => value.isNotEmpty)
        .where((value) => value.toLowerCase().contains(normalized))
        .toSet()
        .take(5)
        .toList();
  }

  Future<List<AppealRecordModel>> _fetchAllAppeals({int pageSize = 50}) async {
    if (!await _validateJwtToken()) {
      NavigationHelper.offAllNamed(Routes.login);
      return [];
    }
    await appealApi.initializeWithJwt();
    await offenseApi.initializeWithJwt();
    final offenses = await offenseApi.listOffenses();
    final List<AppealRecordModel> results = [];
    for (final offense in offenses.take(_maxOffenseBatch)) {
      final offenseId = offense.offenseId;
      if (offenseId == null) continue;
      try {
        final subset = await appealApi.listAppeals(
          offenseId: offenseId,
          page: 1,
          size: pageSize,
        );
        results.addAll(subset);
      } catch (e) {
        developer.log('Failed to load appeals for offense $offenseId: $e',
            name: 'AppealManagement');
      }
    }
    return results;
  }

  Future<void> _loadAppeals({bool reset = false, String? query}) async {
    if (!_isAdmin) return;

    if (reset) {
      _appeals.clear();
      _filteredAppeals.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appeals = await _fetchAllAppeals();
      setState(() {
        _appeals = appeals;
        _applyFilters(query ?? _searchController.text);
        if (_filteredAppeals.isEmpty) {
          _errorMessage = (_searchController.text.isNotEmpty ||
                  (_startTime != null && _endTime != null))
              ? '未找到符合条件的申诉记录'
              : '暂无申诉记录';
        }
      });
      developer.log('Loaded appeals: ${_appeals.length}');
    } catch (e) {
      developer.log('Error fetching appeals: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _appeals.clear();
        _filteredAppeals.clear();
        if (e is ApiException && e.code == 403) {
          _errorMessage = '未授权，请重新登录';
        } else {
          _errorMessage = '加载申诉信息失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredAppeals = _appeals.where((appeal) {
        final reason = (appeal.appealReason ?? '').toLowerCase();
        final name = (appeal.appellantName ?? '').toLowerCase();
        final status = getDisplayStatus(appeal.processStatus)
            .toLowerCase(); // Use Chinese status for filtering
        final appealTime = appeal.appealTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'appealReason') {
            matchesQuery = reason.contains(searchQuery);
          } else if (_searchType == 'appellantName') {
            matchesQuery = name.contains(searchQuery);
          } else if (_searchType == 'processStatus') {
            matchesQuery = status.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && appealTime != null) {
          matchesDateRange = appealTime.isAfter(_startTime!) &&
              appealTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            appealTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredAppeals.isEmpty && _appeals.isNotEmpty) {
        _errorMessage = '未找到符合条件的申诉记录';
      } else {
        _errorMessage =
            _filteredAppeals.isEmpty && _appeals.isEmpty ? '暂无申诉记录' : '';
      }
    });
  }

  Future<void> _refreshAppeals({String? query}) async {
    setState(() {
      _appeals.clear();
      _filteredAppeals.clear();
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startTime = null;
        _endTime = null;
        _searchType = 'appealReason';
      }
    });
    await _loadAppeals(reset: true, query: query);
  }

  void _goToDetailPage(AppealRecordModel appeal) {
    Get.to(() => AppealDetailPage(
          appeal: appeal,
          onAppealUpdated: (updatedAppeal) {
            setState(() {
              final index = _appeals
                  .indexWhere((a) => a.appealId == updatedAppeal.appealId);
              if (index != -1) {
                _appeals[index] = updatedAppeal;
              }
              _applyFilters(_searchController.text);
            });
          },
        ))?.then((value) {
      if (value == true && mounted) _refreshAppeals();
    });
  }

  // ignore: unused_element
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    Get.snackbar(
      isError ? '错误' : '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
      duration: const Duration(seconds: 3),
    );
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

  Widget _buildSearchBar(ThemeData themeData) {
    return SearchFilterBar(
      controller: _searchController,
      wrapInCard: true,
      cardColor: themeData.colorScheme.surfaceContainerLowest,
      fillColor: themeData.colorScheme.surfaceContainer,
      inputBorderless: true,
      searchEnabled: _searchType != 'timeRange',
      clearButtonIncludesDateRange: true,
      searchTypes: const [
        SearchFilterOption(
          value: 'appealReason',
          label: '按申诉原因',
          hintText: '搜索申诉原因',
        ),
        SearchFilterOption(
          value: 'appellantName',
          label: '按申诉人姓名',
          hintText: '搜索申诉人姓名',
        ),
        SearchFilterOption(
          value: 'processStatus',
          label: '按处理状态',
          hintText: '搜索处理状态',
        ),
        SearchFilterOption(
          value: 'timeRange',
          label: '按时间范围',
          hintText: '搜索时间范围（已选择）',
        ),
      ],
      selectedSearchType: _searchType,
      onTypeChanged: (value) {
        setState(() {
          _searchType = value;
          _searchController.clear();
          _startTime = null;
          _endTime = null;
          _applyFilters('');
        });
      },
      suggestions: (query) async {
        if (_searchType == 'timeRange') return const Iterable<String>.empty();
        return _fetchAutocompleteSuggestions(query);
      },
      showDateRange: true,
      startDate: _startTime,
      endDate: _endTime,
      dateRangeTextBuilder: (start, end) =>
          '日期范围: ${formatDateTime(start)} 至 ${formatDateTime(end)}',
      onDateRangeChanged: (range) {
        setState(() {
          _startTime = range?.start;
          _endTime = range?.end;
          _searchType = range == null ? 'appealReason' : 'timeRange';
          _searchController.clear();
        });
        _applyFilters('');
      },
      onSearch: _applyFilters,
      onClear: () {
        _searchController.clear();
        setState(() {
          _startTime = null;
          _endTime = null;
          _searchType = 'appealReason';
        });
        _applyFilters('');
      },
    );
  }

  Widget _buildAppealCard(AppealRecordModel appeal, ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
          style: themeData.textTheme.titleMedium?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '原因: ${appeal.appealReason ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '状态: ${getDisplayStatus(appeal.processStatus)}',
                // Use Chinese status
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: getAppealProcessStatusColor(
                      appeal.processStatus, themeData),
                ),
              ),
              Text(
                '时间: ${formatDateTime(appeal.appealTime)}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 18,
        ),
        onTap: () => _goToDetailPage(appeal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return DashboardPageTemplate(
        theme: themeData,
        title: '申诉审批管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.refresh,
            onPressed: () => _refreshAppeals(),
            tooltip: '刷新列表',
          ),
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(themeData),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const LoadingView()
                    : _errorMessage.isNotEmpty
                        ? (_errorMessage.contains('未找到') ||
                                _errorMessage.contains('暂无')
                            ? EmptyStateView(
                                message: _errorMessage,
                                icon: CupertinoIcons.doc,
                              )
                            : ErrorStateView(
                                message: _errorMessage,
                                actionLabel: '重新登录',
                                onRetry: _errorMessage.contains('未授权') ||
                                        _errorMessage.contains('登录') ||
                                        _errorMessage.contains('权限不足')
                                    ? () => NavigationHelper.offAllNamed(Routes.login)
                                    : null,
                              ))
                        : _filteredAppeals.isEmpty
                            ? EmptyStateView(
                                message: _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : '暂无申诉记录',
                                icon: CupertinoIcons.doc,
                              )
                            : CupertinoScrollbar(
                                thumbVisibility: true,
                                thickness: 6.0,
                                thicknessWhileDragging: 10.0,
                                child: RefreshIndicator(
                                  onRefresh: () => _refreshAppeals(),
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: ListView.builder(
                                    itemCount: _filteredAppeals.length,
                                    itemBuilder: (context, index) {
                                      final appeal = _filteredAppeals[index];
                                      return _buildAppealCard(
                                          appeal, themeData);
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

class AppealDetailPage extends StatefulWidget {
  final AppealRecordModel appeal;
  final Function(AppealRecordModel)? onAppealUpdated;

  const AppealDetailPage(
      {super.key, required this.appeal, this.onAppealUpdated});

  @override
  State<AppealDetailPage> createState() => _AppealDetailPageState();
}

class _AppealDetailPageState extends State<AppealDetailPage> {
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final ManagerDashboardController controller =
      Get.find<ManagerDashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _validateJwtToken() async {
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权：未找到登录信息，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer.log('JWT token validated successfully for appeal request');
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息：$e，请重新登录');
      developer.log('JWT validation failed: $e',
          stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        developer.log('JWT token refreshed successfully');
        return newJwt;
      }
      developer.log(
          'Refresh token request failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      developer.log('Error refreshing JWT token: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      await appealApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
      developer.log('Initialization failed: $e',
          stackTrace: StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/users/me'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          developer.log('User data from /api/users/me: $userData');
          final roles = (userData['roles'] as List<dynamic>?)
              ?.map((r) => r.toString().toUpperCase())
              .toList();
          if (roles != null && roles.contains('ADMIN')) {
            setState(() => _isAdmin = true);
            return;
          }
          developer.log(
              'No valid roles in /api/users/me response, falling back to JWT');
        } else {
          developer.log(
              'Failed to fetch user roles: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        developer.log('Error fetching user roles from API: $e');
      }

      // Fallback to JWT token roles
      await _checkRolesFromJwt();
    } catch (e) {
      setState(() => _errorMessage = '验证角色失败: $e');
      developer.log('Role check failed: $e', stackTrace: StackTrace.current);
    }
  }

  Future<void> _checkRolesFromJwt() async {
    try {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      developer.log('JWT decoded: $decodedToken');
      final rawRoles = decodedToken['roles'];
      List<String> roles;
      if (rawRoles is String) {
        roles = rawRoles
            .split(',')
            .map((role) => role.trim().toUpperCase())
            .toList();
      } else if (rawRoles is List<dynamic>) {
        roles = rawRoles.map((role) => role.toString().toUpperCase()).toList();
      } else {
        roles = [];
      }
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：JWT角色为 $roles，非管理员');
      }
      developer.log('Roles from JWT: $roles, isAdmin: $_isAdmin');
    } catch (e) {
      setState(() => _errorMessage = '从JWT验证角色失败: $e');
      developer.log('JWT role check failed: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<AppealRecordModel> _triggerAppealWorkflowEvent(
    int appealId,
    AppealProcessEventType event,
  ) async {
    if (!await _validateJwtToken()) {
      NavigationHelper.offAllNamed(Routes.login);
      throw ApiException(401, '未授权');
    }
    final jwtToken = await AuthTokenStore.instance.getJwtToken();
    final response = await http.post(
      Uri.parse(
          '${AppConfig.apiBaseUrl}/api/workflow/appeals/$appealId/events/${event.code}'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Idempotency-Key': generateIdempotencyKey(),
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return AppealRecordModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException(
      response.statusCode,
      response.body.isEmpty ? '工作流事件提交失败' : response.body,
    );
  }

  Future<void> _approveAppeal(int appealId) async {
    if (widget.appeal.appealId == null) {
      _showSnackBar('申诉ID无效', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedAppeal = await _triggerAppealWorkflowEvent(
          appealId, AppealProcessEventType.approve);
      developer.log('Approving appeal ID: $appealId via workflow event');
      _showSnackBar('申诉已审批通过！');
      widget.onAppealUpdated?.call(updatedAppeal);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      developer.log('Error approving appeal: $e',
          stackTrace: StackTrace.current);
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAppeal(int appealId) async {
    final themeData = controller.currentBodyTheme.value;
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: themeData,
        child: Dialog(
          backgroundColor: themeData.colorScheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '驳回申诉',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: '驳回原因',
                    labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: themeData.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        '取消',
                        style: themeData.textTheme.labelLarge?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reason = _rejectionReasonController.text.trim();
                        if (reason.isEmpty) {
                          _showSnackBar('请填写驳回原因', isError: true);
                          return;
                        }
                        if (widget.appeal.appealId == null) {
                          _showSnackBar('申诉ID无效', isError: true);
                          Navigator.pop(ctx);
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          final updatedAppeal =
                              await _triggerAppealWorkflowEvent(
                                  appealId, AppealProcessEventType.reject);
                          developer.log(
                              'Rejecting appeal ID: $appealId via workflow event');
                          _showSnackBar('申诉已驳回，用户可重新提交');
                          widget.onAppealUpdated?.call(updatedAppeal);
                          Navigator.pop(ctx);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          developer.log('Error rejecting appeal: $e',
                              stackTrace: StackTrace.current);
                          _showSnackBar(_formatErrorMessage(e), isError: true);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.error,
                        foregroundColor: themeData.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                      ),
                      child: Text(
                        '确认驳回',
                        style: themeData.textTheme.labelLarge?.copyWith(
                          color: themeData.colorScheme.onError,
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    Get.snackbar(
      isError ? '错误' : '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
      duration: const Duration(seconds: 3),
    );
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

  Widget _buildDetailRow(String label, String value, ThemeData themeData,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              label == '处理状态' ? getDisplayStatus(value) : value,
              // Use Chinese status for display
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: valueColor ?? themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final appealId = widget.appeal.appealId?.toString() ?? '未提供';
      final offenseId = widget.appeal.offenseId?.toString() ?? '未提供';
      final name = widget.appeal.appellantName ?? '未提供';
      final idCard = widget.appeal.appellantIdCard ?? '未提供';
      final contact = widget.appeal.appellantContact ?? '未提供';
      final reason = widget.appeal.appealReason ?? '未提供';
      final time = formatDateTime(widget.appeal.appealTime);
      final status = widget.appeal.processStatus ?? '未提供';
      final result = widget.appeal.processResult ?? '未提供';

      return DashboardPageTemplate(
        theme: themeData,
        title: '申诉详情',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const LoadingView()
              : _errorMessage.isNotEmpty
                  ? ErrorStateView(
                      message: _errorMessage,
                      actionLabel: '重新登录',
                      onRetry: _errorMessage.contains('未授权') ||
                              _errorMessage.contains('登录') ||
                              _errorMessage.contains('权限不足')
                          ? () => NavigationHelper.offAllNamed(Routes.login)
                          : null,
                    )
                  : CupertinoScrollbar(
                      controller: ScrollController(),
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 4,
                              color:
                                  themeData.colorScheme.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                        '申诉ID', appealId, themeData),
                                    _buildDetailRow(
                                        '违法记录ID', offenseId, themeData),
                                    _buildDetailRow('上诉人姓名', name, themeData),
                                    _buildDetailRow('身份证号码', idCard, themeData),
                                    _buildDetailRow('联系电话', contact, themeData),
                                    _buildDetailRow('上诉原因', reason, themeData),
                                    _buildDetailRow('上诉时间', time, themeData),
                                    _buildDetailRow('处理状态', status, themeData,
                                        valueColor: getAppealProcessStatusColor(
                                            status, themeData)),
                                    _buildDetailRow('处理结果', result, themeData),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_isAdmin &&
                                (canApprove(status) || canReject(status))) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _approveAppeal(
                                        widget.appeal.appealId ?? 0),
                                    icon: const Icon(CupertinoIcons.checkmark,
                                        size: 20),
                                    label: const Text('通过'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 12.0),
                                      elevation: 2,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _rejectAppeal(
                                        widget.appeal.appealId ?? 0),
                                    icon: const Icon(CupertinoIcons.xmark,
                                        size: 20),
                                    label: const Text('驳回'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          themeData.colorScheme.error,
                                      foregroundColor:
                                          themeData.colorScheme.onError,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 12.0),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 20.0),
                                  decoration: BoxDecoration(
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    _isAdmin
                                        ? '此申诉已处理，无法再次审批'
                                        : '权限不足，仅管理员可审批申诉',
                                    style:
                                        themeData.textTheme.bodyLarge?.copyWith(
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      );
    });
  }
}
