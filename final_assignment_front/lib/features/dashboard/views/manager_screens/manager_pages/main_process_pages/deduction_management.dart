import 'dart:convert';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '无';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<DeductionInformation> _deductions = [];
  List<DeductionInformation> _filteredDeductions = [];
  String _searchType = 'handler';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final DashboardController controller = Get.find<DashboardController>();

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
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
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
        await deductionApi.initializeWithJwt();
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await prefs.setString('jwtToken', newJwt);
        return newJwt;
      }
      return null;
    } catch (e) {
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
      await deductionApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN' ||
          (decodedToken['roles'] is List &&
              decodedToken['roles'].contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
        return;
      }
      await _loadDeductions(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
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
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
        if (!_isAdmin) {
          setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
        }
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '验证角色失败: $e');
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      if (_searchType == 'handler') {
        final deductions = await deductionApi.apiDeductionsByHandlerGet(
          handler: prefix.trim(),
        );
        return deductions
                ?.map((deduction) => deduction.handler ?? '')
                .where((handler) =>
                    handler.toLowerCase().contains(prefix.toLowerCase()))
                .take(5)
                .toList() ??
            [];
      } else if (_searchType == 'driverLicenseNumber') {
        final deductions = await deductionApi.apiDeductionsGet();
        return deductions
                ?.map((deduction) => deduction.driverLicenseNumber ?? '')
                .where((license) =>
                    license.toLowerCase().contains(prefix.toLowerCase()))
                .take(5)
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      developer.log('Failed to fetch autocomplete suggestions: $e',
          stackTrace: StackTrace.current);
      return [];
    }
  }

  Future<void> _loadDeductions({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _deductions.clear();
      _filteredDeductions.clear();
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
      List<DeductionInformation> deductions = [];
      final searchQuery = query?.trim() ?? '';
      if (searchQuery.isEmpty && _startTime == null && _endTime == null) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
      } else if (_searchType == 'handler' && searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsByHandlerGet(
                handler: searchQuery) ??
            [];
      } else if (_searchType == 'driverLicenseNumber' &&
          searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
        deductions = deductions
            .where((d) => (d.driverLicenseNumber ?? '')
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      } else if (_searchType == 'timeRange' &&
          _startTime != null &&
          _endTime != null) {
        deductions = await deductionApi.apiDeductionsByTimeRangeGet(
              startTime: _startTime!.toIso8601String(),
              endTime: _endTime!.add(const Duration(days: 1)).toIso8601String(),
            ) ??
            [];
      }

      setState(() {
        _deductions.addAll(deductions);
        _hasMore = deductions.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredDeductions.isEmpty) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
                  ? '未找到符合条件的扣分记录'
                  : '暂无扣分记录';
        }
        _currentPage++;
      });
      developer.log('Loaded deductions: ${_deductions.length}');
    } catch (e) {
      developer.log('Error fetching deductions: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is ApiException && e.code == 404) {
          _deductions.clear();
          _filteredDeductions.clear();
          _errorMessage = '未找到符合条件的扣分记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(AppPages.login);
        } else {
          _errorMessage = '获取扣分记录失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
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

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredDeductions.clear();
      _filteredDeductions = _deductions.where((deduction) {
        final handler = (deduction.handler ?? '').toLowerCase();
        final driverLicenseNumber =
            (deduction.driverLicenseNumber ?? '').toLowerCase();
        final deductionTime = deduction.deductionTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'handler') {
            matchesQuery = handler.contains(searchQuery);
          } else if (_searchType == 'driverLicenseNumber') {
            matchesQuery = driverLicenseNumber.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && deductionTime != null) {
          matchesDateRange = deductionTime.isAfter(_startTime!) &&
              deductionTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            deductionTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredDeductions.isEmpty && _deductions.isNotEmpty) {
        _errorMessage = '未找到符合条件的扣分记录';
      } else {
        _errorMessage =
            _filteredDeductions.isEmpty && _deductions.isEmpty ? '暂无扣分记录' : '';
      }
    });
  }

  Future<void> _loadMoreDeductions() async {
    if (!_isLoading && _hasMore) {
      await _loadDeductions();
    }
  }

  Future<void> _refreshDeductions({String? query}) async {
    setState(() {
      _deductions.clear();
      _filteredDeductions.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startTime = null;
        _endTime = null;
        _searchType = 'handler';
      }
    });
    await _loadDeductions(reset: true, query: query);
  }

  Future<void> _searchDeductions() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  void _createDeduction() {
    Get.to(() => const AddDeductionPage())?.then((value) {
      if (value == true && mounted) _refreshDeductions();
    });
  }

  void _goToDetailPage(DeductionInformation deduction) {
    Get.to(() => DeductionDetailPage(deduction: deduction))?.then((value) {
      if (value == true && mounted) _refreshDeductions();
    });
  }

  Future<void> _deleteDeduction(int deductionId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此扣分记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (!await _validateJwtToken()) {
          Get.offAllNamed(AppPages.login);
          return;
        }
        await deductionApi.apiDeductionsDeductionIdDelete(
            deductionId: deductionId);
        _showSnackBar('删除扣分记录成功！');
        await _refreshDeductions();
      } catch (e) {
        _showSnackBar(_formatErrorMessage(e), isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty ||
                        (_searchType != 'handler' &&
                            _searchType != 'driverLicenseNumber')) {
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
                    _searchController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: _searchType == 'handler'
                            ? '搜索处理人'
                            : _searchType == 'driverLicenseNumber'
                                ? '搜索驾驶证号'
                                : '搜索时间范围（已选择）',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search,
                            color: themeData.colorScheme.primary),
                        suffixIcon: controller.text.isNotEmpty ||
                                (_startTime != null && _endTime != null)
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color:
                                        themeData.colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  controller.clear();
                                  _searchController.clear();
                                  setState(() {
                                    _startTime = null;
                                    _endTime = null;
                                    _searchType = 'handler';
                                  });
                                  _applyFilters('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      onChanged: (value) => _applyFilters(value),
                      onSubmitted: (value) => _applyFilters(value),
                      enabled: _searchType == 'handler' ||
                          _searchType == 'driverLicenseNumber',
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
                items: <String>['handler', 'driverLicenseNumber', 'timeRange']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'handler'
                          ? '按处理人'
                          : value == 'driverLicenseNumber'
                              ? '按驾驶证号'
                              : '按时间范围',
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                dropdownColor: themeData.colorScheme.surfaceContainer,
                icon: Icon(Icons.arrow_drop_down,
                    color: themeData.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _startTime != null && _endTime != null
                      ? '时间范围: ${formatDateTime(_startTime)} 至 ${formatDateTime(_endTime)}'
                      : '选择时间范围',
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
                tooltip: '按时间范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择时间范围',
                    cancelText: '取消',
                    confirmText: '确定',
                    fieldStartHintText: '开始日期',
                    fieldEndHintText: '结束日期',
                    builder: (context, child) => Theme(
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
                    ),
                  );
                  if (range != null) {
                    setState(() {
                      _startTime = range.start;
                      _endTime = range.end;
                      _searchType = 'timeRange';
                    });
                    _applyFilters(_searchController.text);
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
                      _searchType = 'handler';
                    });
                    _applyFilters(_searchController.text);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '扣分信息管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            if (_isAdmin) ...[
              IconButton(
                icon: Icon(Icons.add,
                    color: themeData.colorScheme.onPrimaryContainer, size: 24),
                onPressed: _createDeduction,
                tooltip: '添加扣分记录',
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              IconButton(
                icon: Icon(Icons.refresh,
                    color: themeData.colorScheme.onPrimaryContainer, size: 24),
                onPressed: () => _refreshDeductions(),
                tooltip: '刷新列表',
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
            ],
            IconButton(
              icon: Icon(
                themeData.brightness == Brightness.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _refreshDeductions(),
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSearchField(themeData),
                const SizedBox(height: 12),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          _hasMore) {
                        _loadMoreDeductions();
                      }
                      return false;
                    },
                    child: _isLoading && _currentPage == 1
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  themeData.colorScheme.primary),
                            ),
                          )
                        : _errorMessage.isNotEmpty &&
                                _filteredDeductions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
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
                                        _errorMessage.contains('登录'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Get.offAllNamed(AppPages.login),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeData.colorScheme.primary,
                                            foregroundColor:
                                                themeData.colorScheme.onPrimary,
                                          ),
                                          child: const Text('重新登录'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredDeductions.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredDeductions.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final deduction = _filteredDeductions[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      title: Text(
                                        '扣分: ${deduction.deductedPoints ?? 0} 分',
                                        style: themeData.textTheme.titleMedium
                                            ?.copyWith(
                                          color:
                                              themeData.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '驾驶证号: ${deduction.driverLicenseNumber ?? '无'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '时间: ${formatDateTime(deduction.deductionTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '处理人: ${deduction.handler ?? '未记录'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              size: 18,
                                              color:
                                                  themeData.colorScheme.error,
                                            ),
                                            onPressed: () => _deleteDeduction(
                                                deduction.deductionId ?? 0),
                                            tooltip: '删除扣分记录',
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _goToDetailPage(deduction),
                                    ),
                                  );
                                },
                              ),
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

class AddDeductionPage extends StatefulWidget {
  const AddDeductionPage({super.key});

  @override
  State<AddDeductionPage> createState() => _AddDeductionPageState();
}

class _AddDeductionPageState extends State<AddDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _approverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int? _selectedOffenseId;
  final DashboardController controller = Get.find<DashboardController>();

  String generateIdempotencyKey() => const Uuid().v4();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
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
      await deductionApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _approverController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: prefix.trim(),
        page: 1,
        size: 10,
      );
      return offenses
          .map((o) => o.licensePlate ?? '')
          .where((plate) => plate.toLowerCase().contains(prefix.toLowerCase()))
          .toSet()
          .toList();
    } catch (e) {
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<String?> _fetchDriverLicenseNumber(String? driverName) async {
    if (driverName == null || driverName.trim().isEmpty) {
      _showSnackBar('未提供驾驶员姓名，请手动输入驾驶证号', isError: true);
      return null;
    }
    try {
      final drivers = await driverApi.apiDriversByNameGet(
          query: driverName.trim(), page: 1, size: 1);
      if (drivers.isNotEmpty) {
        return drivers.first.driverLicenseNumber;
      }
      _showSnackBar('未找到与驾驶员姓名匹配的驾驶证号，请手动输入', isError: true);
      return null;
    } catch (e) {
      _showSnackBar('获取驾驶证号失败: $e', isError: true);
      return null;
    }
  }

  Future<void> _onLicensePlateSelected(String licensePlate) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        final latestOffense = offenses.first;
        final driverLicenseNumber =
            await _fetchDriverLicenseNumber(latestOffense.driverName);
        setState(() {
          _selectedOffenseId = latestOffense.offenseId;
          _driverLicenseNumberController.text = driverLicenseNumber ?? '';
          _deductedPointsController.text =
              (latestOffense.deductedPoints ?? 0).toString();
          _dateController.text = formatDateTime(latestOffense.offenseTime);
        });
      } else {
        _showSnackBar('未找到与此车牌相关的违法记录', isError: true);
        setState(() {
          _selectedOffenseId = null;
          _driverLicenseNumberController.clear();
          _deductedPointsController.clear();
          _dateController.clear();
        });
      }
    } catch (e) {
      _showSnackBar('获取违法信息失败: $e', isError: true);
    }
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('请先选择一个违法记录', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final deduction = DeductionInformation(
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse('${_dateController.text}T00:00:00.000'),
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        approver: _approverController.text.trim().isEmpty
            ? null
            : _approverController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        idempotencyKey: idempotencyKey,
      );
      await deductionApi.apiDeductionsPost(
        deductionInformation: deduction,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('创建扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _pickDate() async {
    _showSnackBar('扣分时间不可编辑，必须与违法时间一致', isError: true);
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator,
      bool isAutocomplete = false,
      Future<List<String>> Function(String)? fetchSuggestions,
      void Function(String)? onSelected}) {
    if (isAutocomplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || fetchSuggestions == null) {
              return const Iterable<String>.empty();
            }
            return await fetchSuggestions(textEditingValue.text);
          },
          onSelected: onSelected,
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.text = controller.text;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                    TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                helperText: label == '车牌号' ? '请输入车牌号，例如：黑AWS34' : null,
                helperStyle: TextStyle(
                    color: themeData.colorScheme.onSurfaceVariant
                        .withOpacity(0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          textEditingController.clear();
                          controller.clear();
                          if (label == '车牌号') {
                            setState(() {
                              _selectedOffenseId = null;
                              _driverLicenseNumberController.clear();
                              _deductedPointsController.clear();
                              _dateController.clear();
                            });
                          }
                        },
                      )
                    : null,
              ),
              keyboardType: keyboardType,
              maxLength: maxLength,
              validator: validator ??
                  (value) {
                    final trimmedValue = value?.trim() ?? '';
                    if (required && trimmedValue.isEmpty) return '$label不能为空';
                    if (label == '车牌号') {
                      if (trimmedValue.isEmpty) return '车牌号不能为空';
                      if (trimmedValue.length > 20) return '车牌号不能超过20个字符';
                      if (!RegExp(r'^[\u4e00-\u9fa5][A-Za-z0-9]{5,7}$')
                          .hasMatch(trimmedValue)) {
                        return '请输入有效车牌号，例如：黑AWS34';
                      }
                    }
                    return null;
                  },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == '驾驶证号'
              ? '自动填充或手动输入，与违法记录关联'
              : label == '处理人' || label == '审批人'
                  ? '请输入${label}姓名（选填）'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: controller.text.isNotEmpty && !readOnly
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () => controller.clear(),
                )
              : readOnly
                  ? Icon(Icons.lock,
                      size: 18, color: themeData.colorScheme.primary)
                  : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '扣分分数' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分分数必须是整数';
                if (points <= 0 || points > 12) return '扣分分数必须在1到12之间';
              }
              if (label == '驾驶证号' && trimmedValue.length > 50) {
                return '驾驶证号不能超过50个字符';
              }
              if ((label == '处理人' || label == '审批人') &&
                  trimmedValue.length > 100) {
                return '$label姓名不能超过100个字符';
              }
              if (label == '备注' && trimmedValue.length > 255) {
                return '备注不能超过255个字符';
              }
              if (label == '扣分时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '扣分时间不能晚于当前日期';
                }
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '添加扣分信息',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          elevation: 3,
                          color: themeData.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildTextField(
                                  '车牌号 *',
                                  _licensePlateController,
                                  themeData,
                                  required: true,
                                  maxLength: 20,
                                  isAutocomplete: true,
                                  fetchSuggestions:
                                      _fetchLicensePlateSuggestions,
                                  onSelected: _onLicensePlateSelected,
                                ),
                                _buildTextField(
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                  maxLength: 50,
                                  readOnly: false,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '审批人',
                                  _approverController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                  maxLength: 255,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.primary,
                            foregroundColor: themeData.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 20.0),
                            textStyle: themeData.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('提交'),
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

class EditDeductionPage extends StatefulWidget {
  final DeductionInformation deduction;

  const EditDeductionPage({super.key, required this.deduction});

  @override
  State<EditDeductionPage> createState() => _EditDeductionPageState();
}

class _EditDeductionPageState extends State<EditDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
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
      await deductionApi.initializeWithJwt();
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    _driverLicenseNumberController.text =
        widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text =
        (widget.deduction.deductedPoints ?? 0).toString();
    _handlerController.text = widget.deduction.handler ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text = formatDateTime(widget.deduction.deductionTime);
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

  @override
  void dispose() {
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法更新', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: widget.deduction.driverLicenseNumber,
        deductedPoints: widget.deduction.deductedPoints,
        deductionTime: widget.deduction.deductionTime,
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );
      final idempotencyKey = generateIdempotencyKey();
      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId!,
        deductionInformation: deduction,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('更新扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _pickDate() async {
    _showSnackBar('扣分时间不可编辑，必须与违法时间一致', isError: true);
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == '驾驶证号'
              ? '不可编辑，与违法记录关联'
              : label == '处理人'
                  ? '请输入处理人姓名（选填）'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: readOnly
              ? Icon(Icons.lock, size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '扣分分数' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分分数必须是整数';
                if (points <= 0 || points > 12) return '扣分分数必须在1到12之间';
              }
              if (label == '驾驶证号' && trimmedValue.length > 50) {
                return '驾驶证号不能超过50个字符';
              }
              if (label == '处理人' && trimmedValue.length > 100) {
                return '处理人姓名不能超过100个字符';
              }
              if (label == '备注' && trimmedValue.length > 255) {
                return '备注不能超过255个字符';
              }
              if (label == '扣分时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '扣分时间不能晚于当前日期';
                }
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '编辑扣分信息',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          elevation: 3,
                          color: themeData.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildTextField(
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                  maxLength: 50,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                  maxLength: 255,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.primary,
                            foregroundColor: themeData.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 20.0),
                            textStyle: themeData.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('保存'),
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

class DeductionDetailPage extends StatefulWidget {
  final DeductionInformation deduction;

  const DeductionDetailPage({super.key, required this.deduction});

  @override
  State<DeductionDetailPage> createState() => _DeductionDetailPageState();
}

class _DeductionDetailPageState extends State<DeductionDetailPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  late DeductionInformation _deduction;
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() => _errorMessage = '登录已过期，请重新登录');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _deduction = widget.deduction;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
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
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteDeduction() async {
    if (_deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法删除', isError: true);
      return;
    }
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此扣分记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (!await _validateJwtToken()) {
          Get.offAllNamed(AppPages.login);
          return;
        }
        await deductionApi.apiDeductionsDeductionIdDelete(
            deductionId: _deduction.deductionId!);
        _showSnackBar('扣分记录删除成功！');
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar(_formatErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未提供';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      if (_errorMessage.isNotEmpty) {
        return Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage,
                  style: themeData.textTheme.titleMedium?.copyWith(
                    color: themeData.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage.contains('未授权') ||
                    _errorMessage.contains('登录'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Get.offAllNamed(AppPages.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: themeData.colorScheme.onPrimary,
                      ),
                      child: const Text('重新登录'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '扣分详情',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isAdmin
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Get.to(() => EditDeductionPage(deduction: _deduction))
                          ?.then((value) {
                        if (value == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    },
                    tooltip: '编辑扣分记录',
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: _deleteDeduction,
                    tooltip: '删除扣分记录',
                  ),
                ]
              : [],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(themeData.colorScheme.primary)))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              '扣分ID',
                              _deduction.deductionId?.toString() ?? '未提供',
                              themeData),
                          _buildDetailRow('驾驶证号',
                              _deduction.driverLicenseNumber ?? '无', themeData),
                          _buildDetailRow('扣分分数',
                              '${_deduction.deductedPoints ?? 0} 分', themeData),
                          _buildDetailRow(
                              '扣分时间',
                              formatDateTime(_deduction.deductionTime),
                              themeData),
                          _buildDetailRow(
                              '处理人', _deduction.handler ?? '无', themeData),
                          _buildDetailRow(
                              '审批人', _deduction.approver ?? '无', themeData),
                          _buildDetailRow(
                              '备注', _deduction.remarks ?? '无', themeData),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    });
  }
}
