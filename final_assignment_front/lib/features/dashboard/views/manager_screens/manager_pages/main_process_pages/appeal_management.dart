import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

String generateIdempotencyKey() {
  return const Uuid().v4();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}

class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<AppealManagement> _appeals = [];
  List<AppealManagement> _filteredAppeals = [];
  String _searchType = 'appealReason';
  DateTime? _startTime;
  DateTime? _endTime;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final DashboardController controller = Get.find<DashboardController>();

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
        _loadMoreAppeals();
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
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权：未找到登录信息，请重新登录');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await prefs.setString('jwtToken', jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer
          .log('JWT Token validated successfully: sub=${decodedToken['sub']}');
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
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await prefs.setString('jwtToken', newJwt);
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
        Get.offAllNamed(AppPages.login);
        return;
      }
      await appealApi.initializeWithJwt();
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
        Get.offAllNamed(AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/users/me'),
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
          // If roles are missing or don't contain ADMIN, fall back to JWT
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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
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
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      List<AppealManagement> appeals;
      switch (_searchType) {
        case 'appealReason':
          appeals = await appealApi.apiAppealsGet();
          return appeals
              .map((appeal) => appeal.appealReason ?? '')
              .where((reason) =>
                  reason.toLowerCase().contains(prefix.toLowerCase()))
              .take(5)
              .toList();
        case 'appellantName':
          appeals = await appealApi.apiAppealsGet();
          return appeals
              .map((appeal) => appeal.appellantName ?? '')
              .where(
                  (name) => name.toLowerCase().contains(prefix.toLowerCase()))
              .take(5)
              .toList();
        case 'processStatus':
          appeals = await appealApi.apiAppealsGet();
          return appeals
              .map((appeal) => appeal.processStatus ?? '')
              .where((status) =>
                  status.toLowerCase().contains(prefix.toLowerCase()))
              .take(5)
              .toList();
        default:
          return [];
      }
    } catch (e) {
      developer.log('Failed to fetch autocomplete suggestions: $e',
          stackTrace: StackTrace.current);
      return [];
    }
  }

  Future<void> _loadAppeals({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _appeals.clear();
      _filteredAppeals.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      List<AppealManagement> appeals = [];
      final searchQuery = query?.trim() ?? '';
      if (_searchType == 'appealReason' && searchQuery.isNotEmpty) {
        appeals = await appealApi.apiAppealsReasonReasonGet(
          reason: searchQuery,
        );
      } else if (_searchType == 'appellantName' && searchQuery.isNotEmpty) {
        appeals = await appealApi.apiAppealsGet();
        appeals = appeals
            .where((appeal) =>
                appeal.appellantName
                    ?.toLowerCase()
                    .contains(searchQuery.toLowerCase()) ??
                false)
            .toList();
      } else if (_searchType == 'processStatus' && searchQuery.isNotEmpty) {
        appeals = await appealApi.apiAppealsGet();
        appeals = appeals
            .where((appeal) =>
                appeal.processStatus
                    ?.toLowerCase()
                    .contains(searchQuery.toLowerCase()) ??
                false)
            .toList();
      } else if (_searchType == 'timeRange' &&
          _startTime != null &&
          _endTime != null) {
        appeals = await appealApi.apiAppealsTimeRangeGet(
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.add(const Duration(days: 1)).toIso8601String(),
        );
      } else {
        appeals = await appealApi.apiAppealsGet();
      }

      setState(() {
        _appeals.addAll(appeals);
        _hasMore = appeals.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredAppeals.isEmpty) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
                  ? '未找到符合条件的申诉记录'
                  : '暂无申诉记录';
        }
        _currentPage++;
      });
      developer.log('Loaded appeals: ${_appeals.length}');
    } catch (e) {
      developer.log('Error fetching appeals: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is ApiException && e.code == 404) {
          _appeals.clear();
          _filteredAppeals.clear();
          _errorMessage = '未找到符合条件的申诉记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(AppPages.login);
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
        final status = (appeal.processStatus ?? '').toLowerCase();
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

  Future<void> _loadMoreAppeals() async {
    if (!_isLoading && _hasMore) {
      await _loadAppeals();
    }
  }

  Future<void> _refreshAppeals({String? query}) async {
    setState(() {
      _appeals.clear();
      _filteredAppeals.clear();
      _currentPage = 1;
      _hasMore = true;
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

  void _goToDetailPage(AppealManagement appeal) {
    Get.to(() => AppealDetailPage(appeal: appeal))?.then((value) {
      if (value == true && mounted) _refreshAppeals();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
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
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty ||
                          _searchType == 'timeRange') {
                        return const Iterable<String>.empty();
                      }
                      return await _fetchAutocompleteSuggestions(
                          textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _searchController.text = selection;
                      _applyFilters(selection);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: _searchController,
                        focusNode: focusNode,
                        style: themeData.textTheme.bodyMedium
                            ?.copyWith(color: themeData.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _searchType == 'appealReason'
                              ? '搜索申诉原因'
                              : _searchType == 'appellantName'
                                  ? '搜索申诉人姓名'
                                  : _searchType == 'processStatus'
                                      ? '搜索处理状态'
                                      : '搜索时间范围（已选择）',
                          hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: themeData.colorScheme.primary),
                          suffixIcon: _searchController.text.isNotEmpty ||
                                  (_startTime != null && _endTime != null)
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _startTime = null;
                                      _endTime = null;
                                      _searchType = 'appealReason';
                                    });
                                    _applyFilters('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: themeData.colorScheme.surfaceContainer,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                        ),
                        onChanged: (value) => _applyFilters(value),
                        onSubmitted: (value) => _applyFilters(value),
                        enabled: _searchType != 'timeRange',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _searchType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _searchType = newValue!;
                      _searchController.clear();
                      _startTime = null;
                      _endTime = null;
                      _applyFilters('');
                    });
                  },
                  items: <String>[
                    'appealReason',
                    'appellantName',
                    'processStatus',
                    'timeRange'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value == 'appealReason'
                            ? '按申诉原因'
                            : value == 'appellantName'
                                ? '按申诉人姓名'
                                : value == 'processStatus'
                                    ? '按处理状态'
                                    : '按时间范围',
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  dropdownColor: themeData.colorScheme.surfaceContainer,
                  icon: Icon(Icons.arrow_drop_down,
                      color: themeData.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startTime != null && _endTime != null
                        ? '日期范围: ${formatDateTime(_startTime)} 至 ${formatDateTime(_endTime)}'
                        : '选择日期范围',
                    style: themeData.textTheme.bodyMedium?.copyWith(
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
                          data: themeData.copyWith(
                            colorScheme: themeData.colorScheme.copyWith(
                              primary: themeData.colorScheme.primary,
                              onPrimary: themeData.colorScheme.onPrimary,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: themeData.colorScheme.primary,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _startTime = range.start;
                        _endTime = range.end;
                        _searchType = 'timeRange';
                        _searchController.clear();
                      });
                      _applyFilters('');
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
                        _searchType = 'appealReason';
                        _searchController.clear();
                      });
                      _applyFilters('');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(AppealManagement appeal, ThemeData themeData) {
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
                '状态: ${appeal.processStatus ?? "Pending"}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: appeal.processStatus == 'Approved'
                      ? Colors.green
                      : appeal.processStatus == 'Rejected'
                          ? Colors.red
                          : themeData.colorScheme.onSurfaceVariant,
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

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '申诉审批管理',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _refreshAppeals(),
                  child: Icon(
                    CupertinoIcons.refresh,
                    color: themeData.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: controller.toggleBodyTheme,
                  child: Icon(
                    themeData.brightness == Brightness.light
                        ? CupertinoIcons.moon
                        : CupertinoIcons.sun_max,
                    color: themeData.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchBar(themeData),
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
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_errorMessage.contains('未授权') ||
                                        _errorMessage.contains('登录') ||
                                        _errorMessage.contains('权限不足'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 20.0),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Get.offAllNamed(AppPages.login),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeData.colorScheme.primary,
                                            foregroundColor:
                                                themeData.colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12.0)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0,
                                                vertical: 12.0),
                                          ),
                                          child: const Text('重新登录'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : _filteredAppeals.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                              : '暂无申诉记录',
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
                                      onRefresh: () => _refreshAppeals(),
                                      color: themeData.colorScheme.primary,
                                      backgroundColor: themeData
                                          .colorScheme.surfaceContainer,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: _filteredAppeals.length +
                                            (_hasMore ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index ==
                                                  _filteredAppeals.length &&
                                              _hasMore) {
                                            return const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Center(
                                                  child:
                                                      CupertinoActivityIndicator()),
                                            );
                                          }
                                          final appeal =
                                              _filteredAppeals[index];
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
          ),
        ),
      );
    });
  }
}

class AppealDetailPage extends StatefulWidget {
  final AppealManagement appeal;

  const AppealDetailPage({super.key, required this.appeal});

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
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权：未找到登录信息，请重新登录');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        final newJwt = await _refreshJwtToken();
        if (newJwt == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await prefs.setString('jwtToken', newJwt);
        if (JwtDecoder.isExpired(newJwt)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer
          .log('JWT Token validated successfully: sub=${decodedToken['sub']}');
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
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await prefs.setString('jwtToken', newJwt);
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
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
        Get.offAllNamed(AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/users/me'),
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
          // If roles are missing or don't contain ADMIN, fall back to JWT
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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
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

  Future<void> _approveAppeal(int appealId) async {
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final idempotencyKey = generateIdempotencyKey();
      final appealPayload = {
        'appealId': widget.appeal.appealId,
        'offenseId': widget.appeal.offenseId,
        'appellantName': widget.appeal.appellantName,
        'idCardNumber': widget.appeal.idCardNumber,
        'contactNumber': widget.appeal.contactNumber,
        'appealReason': widget.appeal.appealReason,
        'appealTime': widget.appeal.appealTime?.toIso8601String(),
        'processStatus': 'Approved',
        'processResult': '申诉已通过',
      };
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/appeals/$appealId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(appealPayload),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to approve appeal: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('申诉已审批通过！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
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
                        if (!await _validateJwtToken()) {
                          Get.offAllNamed(AppPages.login);
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final jwtToken = prefs.getString('jwtToken');
                          final idempotencyKey = generateIdempotencyKey();
                          final appealPayload = {
                            'appealId': widget.appeal.appealId,
                            'offenseId': widget.appeal.offenseId,
                            'appellantName': widget.appeal.appellantName,
                            'idCardNumber': widget.appeal.idCardNumber,
                            'contactNumber': widget.appeal.contactNumber,
                            'appealReason': widget.appeal.appealReason,
                            'appealTime':
                                widget.appeal.appealTime?.toIso8601String(),
                            'processStatus': 'Rejected',
                            'processResult': reason,
                          };
                          final response = await http.put(
                            Uri.parse(
                                'http://localhost:8081/api/appeals/$appealId?idempotencyKey=$idempotencyKey'),
                            headers: {
                              'Authorization': 'Bearer $jwtToken',
                              'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: jsonEncode(appealPayload),
                          );
                          if (response.statusCode != 200) {
                            throw Exception(
                                'Failed to reject appeal: ${response.statusCode} - ${response.body}');
                          }
                          _showSnackBar('申诉已驳回，用户可重新提交');
                          Navigator.pop(ctx);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
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
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
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
              value,
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
      final idCard = widget.appeal.idCardNumber ?? '未提供';
      final contact = widget.appeal.contactNumber ?? '未提供';
      final reason = widget.appeal.appealReason ?? '未提供';
      final time = formatDateTime(widget.appeal.appealTime);
      final status = widget.appeal.processStatus ?? '未提供';
      final result = widget.appeal.processResult ?? '未提供';

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '申诉详情',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Column(
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
                              style: themeData.textTheme.titleMedium?.copyWith(
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
                                      Get.offAllNamed(AppPages.login),
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
                                  color: themeData
                                      .colorScheme.surfaceContainerLowest,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                            '申诉ID', appealId, themeData),
                                        _buildDetailRow(
                                            '违法记录ID', offenseId, themeData),
                                        _buildDetailRow(
                                            '上诉人姓名', name, themeData),
                                        _buildDetailRow(
                                            '身份证号码', idCard, themeData),
                                        _buildDetailRow(
                                            '联系电话', contact, themeData),
                                        _buildDetailRow(
                                            '上诉原因', reason, themeData),
                                        _buildDetailRow(
                                            '上诉时间', time, themeData),
                                        _buildDetailRow(
                                            '处理状态', status, themeData,
                                            valueColor: status == 'Approved'
                                                ? Colors.green
                                                : status == 'Rejected'
                                                    ? Colors.red
                                                    : themeData.colorScheme
                                                        .onSurfaceVariant),
                                        _buildDetailRow(
                                            '处理结果', result, themeData),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_isAdmin && status == 'Pending') ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _approveAppeal(
                                            widget.appeal.appealId ?? 0),
                                        icon: const Icon(
                                            CupertinoIcons.checkmark,
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
                                        color: themeData
                                            .colorScheme.surfaceContainer,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        _isAdmin
                                            ? '此申诉已处理，无法再次审批'
                                            : '权限不足，仅管理员可审批申诉',
                                        style: themeData.textTheme.bodyLarge
                                            ?.copyWith(
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
          ),
        ),
      );
    });
  }
}
