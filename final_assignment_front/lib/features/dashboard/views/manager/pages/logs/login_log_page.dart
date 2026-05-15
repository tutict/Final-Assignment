// ignore_for_file: use_build_context_synchronously
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/features/api/login_log_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/shared/dialogs/app_dialog.dart';
import 'package:final_assignment_front/shared/widgets/index.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String generateIdempotencyKey() {
  return const Uuid().v4();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
}

class LoginLogPage extends StatefulWidget {
  const LoginLogPage({super.key});

  @override
  State<LoginLogPage> createState() => _LoginLogPageState();
}

class _LoginLogPageState extends State<LoginLogPage> {
  final LoginLogControllerApi logApi = LoginLogControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ManagerDashboardController controller =
      Get.find<ManagerDashboardController>();
  final List<LoginLog> _logs = [];
  List<LoginLog> _filteredLogs = [];
  String _searchType = 'username';
  DateTime? _startTime;
  DateTime? _endTime;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      _applyFilters(_searchController.text);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMore &&
          !_isLoading) {
        _loadMoreLogs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    String? jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        final refreshed = await Get.find<AuthService>().refreshJwtToken();
        jwtToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed || jwtToken == null || JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
      }
      await logApi.initializeWithJwt();
      final decodedToken = JwtDecoder.decode(jwtToken);
      _currentUsername = decodedToken['sub']?.toString() ?? '';
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      await logApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) {
        await _fetchLogs(reset: true);
      } else {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
      }
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      final roles = decodedToken['roles'] is List
          ? (decodedToken['roles'] as List).map((r) => r.toString()).toList()
          : decodedToken['roles'] is String
              ? [decodedToken['roles'].toString()]
              : [];
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
      }
      developer.log('User roles from JWT: $roles');
    } catch (e) {
      setState(() => _errorMessage = '验证角色失败: $e');
      developer.log('Error checking user role: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<void> _fetchLogs({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _logs.clear();
      _filteredLogs.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      final logs = await logApi.listLoginLogs();
      setState(() {
        _logs.addAll(logs);
        _hasMore = false;
        _applyFilters(query ?? _searchController.text);
        if (_filteredLogs.isEmpty) {
          _errorMessage = (_searchController.text.isNotEmpty ||
                  (_startTime != null && _endTime != null))
              ? '未找到符合条件的日志记录'
              : '暂无日志记录';
        }
        _currentPage = 1;
      });
      developer.log('Loaded logs: ${_logs.length}');
    } catch (e) {
      developer.log('Error fetching logs: $e', stackTrace: StackTrace.current);
      setState(() {
        if (e is AppException && e.code == 404) {
          _logs.clear();
          _filteredLogs.clear();
          _errorMessage = '未找到符合条件的日志记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '您没有权限查看日志信息';
        } else {
          _errorMessage = '加载日志信息失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredLogs = _logs.where((log) {
        final username = (log.username ?? '').toLowerCase();
        final loginResult = (log.loginResult ?? '').toLowerCase();
        final loginTime = log.loginTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'username') {
            matchesQuery = username.contains(searchQuery);
          } else if (_searchType == 'loginResult') {
            matchesQuery = loginResult.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && loginTime != null) {
          matchesDateRange = loginTime.isAfter(_startTime!) &&
              loginTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            loginTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredLogs.isEmpty && _logs.isNotEmpty) {
        _errorMessage = '未找到符合条件的日志记录';
      } else {
        _errorMessage = _filteredLogs.isEmpty && _logs.isEmpty ? '暂无日志记录' : '';
      }
    });
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    final normalized = prefix.toLowerCase();
    final values = _searchType == 'username'
        ? _logs.map((log) => log.username ?? '')
        : _logs.map((log) => log.loginResult ?? '');
    return values
        .where((value) => value.isNotEmpty)
        .where((value) => value.toLowerCase().contains(normalized))
        .toSet()
        .take(5)
        .toList();
  }

  Future<void> _loadMoreLogs() async {
    if (!_isLoading && _hasMore) {
      await _fetchLogs();
    }
  }

  Future<void> _refreshLogs({String? query}) async {
    setState(() {
      _logs.clear();
      _filteredLogs.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startTime = null;
        _endTime = null;
        _searchType = 'username';
      }
    });
    await _fetchLogs(reset: true, query: query);
  }

  // ignore: unused_element
  Future<void> _showCreateLogDialog() async {
    final usernameController = TextEditingController(text: _currentUsername);
    final loginIpController = TextEditingController();
    final loginResultController = TextEditingController();
    final browserTypeController = TextEditingController();
    final osVersionController = TextEditingController();
    final remarksController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = generateIdempotencyKey();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return Theme(
          data: themeData,
          child: AlertDialog(
            title: Text('创建登录日志', style: themeData.textTheme.titleLarge),
            backgroundColor: themeData.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) => value!.isEmpty ? '用户名不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: loginIpController,
                      decoration: InputDecoration(
                        labelText: '登录IP地址',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? '登录IP地址不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: loginResultController,
                      decoration: InputDecoration(
                        labelText: '登录结果',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) => value!.isEmpty ? '登录结果不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: browserTypeController,
                      decoration: InputDecoration(
                        labelText: '浏览器类型',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: osVersionController,
                      decoration: InputDecoration(
                        labelText: '操作系统版本',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消',
                    style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      NavigationHelper.offAllNamed(Routes.login);
                      return;
                    }
                    try {
                      final newLog = LoginLog(
                        username: usernameController.text,
                        loginIp: loginIpController.text,
                        loginResult: loginResultController.text,
                        browserType: browserTypeController.text.isEmpty
                            ? null
                            : browserTypeController.text,
                        osVersion: osVersionController.text.isEmpty
                            ? null
                            : osVersionController.text,
                        remarks: remarksController.text.isEmpty
                            ? null
                            : remarksController.text,
                        loginTime: DateTime.now(),
                      );
                      await logApi.createLoginLog(
                        loginLog: newLog,
                        idempotencyKey: idempotencyKey,
                      );
                      _showSnackBar('日志创建成功');
                      Navigator.pop(context);
                      await _refreshLogs();
                    } catch (e) {
                      _showSnackBar(_formatErrorMessage(e), isError: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('创建'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditLogDialog(LoginLog log) async {
    final logId = log.logId;
    if (logId == null) {
      _showSnackBar('无法编辑：日志ID缺失', isError: true);
      return;
    }
    final usernameController = TextEditingController(text: log.username);
    final loginIpController = TextEditingController(text: log.loginIp ?? '');
    final loginResultController = TextEditingController(text: log.loginResult);
    final browserTypeController = TextEditingController(text: log.browserType);
    final osVersionController = TextEditingController(text: log.osVersion);
    final remarksController = TextEditingController(text: log.remarks);
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = generateIdempotencyKey();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return Theme(
          data: themeData,
          child: AlertDialog(
            title: Text('编辑登录日志', style: themeData.textTheme.titleLarge),
            backgroundColor: themeData.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) => value!.isEmpty ? '用户名不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: loginIpController,
                      decoration: InputDecoration(
                        labelText: '登录IP地址',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? '登录IP地址不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: loginResultController,
                      decoration: InputDecoration(
                        labelText: '登录结果',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      validator: (value) => value!.isEmpty ? '登录结果不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: browserTypeController,
                      decoration: InputDecoration(
                        labelText: '浏览器类型',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: osVersionController,
                      decoration: InputDecoration(
                        labelText: '操作系统版本',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消',
                    style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      NavigationHelper.offAllNamed(Routes.login);
                      return;
                    }
                    try {
                      final updatedLog = LoginLog(
                        logId: log.logId,
                        username: usernameController.text,
                        loginIp: loginIpController.text,
                        loginResult: loginResultController.text,
                        loginTime: log.loginTime,
                        browserType: browserTypeController.text.isEmpty
                            ? null
                            : browserTypeController.text,
                        osVersion: osVersionController.text.isEmpty
                            ? null
                            : osVersionController.text,
                        remarks: remarksController.text.isEmpty
                            ? null
                            : remarksController.text,
                      );
                      await logApi.updateLoginLog(
                        logId: logId,
                        loginLog: updatedLog,
                        idempotencyKey: idempotencyKey,
                      );
                      _showSnackBar('日志更新成功');
                      Navigator.pop(context);
                      await _refreshLogs();
                    } catch (e) {
                      _showSnackBar(_formatErrorMessage(e), isError: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteLog(int logId) async {
    final confirmed = await AppDialog.showConfirmDelete(
      context,
      itemName: '该日志',
      extraWarning: '此操作不可撤销。',
    );

    if (confirmed == true) {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      try {
        await logApi.deleteLoginLog(logId: logId);
        _showSnackBar('日志删除成功');
        await _refreshLogs();
      } catch (e) {
        _showSnackBar(_formatErrorMessage(e), isError: true);
      }
    }
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
    if (error is AppException) {
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
          value: 'username',
          label: '按用户名',
          hintText: '搜索用户名',
        ),
        SearchFilterOption(
          value: 'loginResult',
          label: '按登录结果',
          hintText: '搜索登录结果',
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
          _searchType = range == null ? 'username' : 'timeRange';
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
          _searchType = 'username';
        });
        _applyFilters('');
      },
    );
  }

  Widget _buildLogCard(LoginLog log, ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          '日志ID: ${log.logId ?? "未知"}',
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
                '用户名: ${log.username ?? "未知"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '登录IP地址: ${log.loginIp ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '登录结果: ${log.loginResult ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '登录时间: ${formatDateTime(log.loginTime)}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '浏览器类型: ${log.browserType ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '操作系统版本: ${log.osVersion ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '备注: ${log.remarks ?? "无"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: _isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.edit, color: themeData.colorScheme.primary),
                    onPressed: () => _showEditLogDialog(log),
                    tooltip: '编辑日志',
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: () {
                      final logId = log.logId;
                      if (logId == null) {
                        _showSnackBar('无法删除：日志ID缺失', isError: true);
                        return;
                      }
                      _deleteLog(logId);
                    },
                    tooltip: '删除日志',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: '登录日志',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onRefresh: _refreshLogs,
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isAdmin) _buildSearchBar(themeData),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading && _currentPage == 1
                    ? Center(
                        child: CupertinoActivityIndicator(
                          color: themeData.colorScheme.primary,
                          radius: 16.0,
                        ),
                      )
                    : _errorMessage.isNotEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: themeData.colorScheme.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  style:
                                      themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_errorMessage.contains('未授权') ||
                                    _errorMessage.contains('登录') ||
                                    _errorMessage.contains('权限不足'))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          NavigationHelper.offAllNamed(Routes.login),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            themeData.colorScheme.primary,
                                        foregroundColor:
                                            themeData.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24.0, vertical: 12.0),
                                      ),
                                      child: const Text('重新登录'),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _filteredLogs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage.isNotEmpty
                                          ? _errorMessage
                                          : '暂无日志记录',
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : CupertinoScrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6.0,
                                thicknessWhileDragging: 10.0,
                                child: RefreshIndicator(
                                  onRefresh: () => _refreshLogs(),
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _filteredLogs.length +
                                        (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _filteredLogs.length &&
                                          _hasMore) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(
                                              child:
                                                  CupertinoActivityIndicator()),
                                        );
                                      }
                                      final log = _filteredLogs[index];
                                      return _buildLogCard(log, themeData);
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
