// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

// Utility methods for validation
bool isValidLicensePlate(String value) {
  final regex = RegExp(r'^[\u4e00-\u9fa5][A-Za-z0-9]{5,7}$');
  return regex.hasMatch(value);
}

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return '未设置';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPageState();
}

class _OffenseListPageState extends State<OffenseList> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<OffenseInformation> _offenseList = [];
  List<OffenseInformation> _filteredOffenseList = [];
  String _searchType = 'driverName';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startDate;
  DateTime? _endDate;
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
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
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
        await offenseApi.initializeWithJwt();
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
        await AuthTokenStore.instance.setJwtToken(newJwt);
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
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      await offenseApi.initializeWithJwt();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN';
      await _checkUserRole();
      await _fetchOffenses(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;

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

  Future<void> _fetchOffenses({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _offenseList.clear();
      _filteredOffenseList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      List<OffenseInformation> offenses = await offenseApi.apiOffensesGet();

      setState(() {
        _offenseList.addAll(offenses);
        _hasMore = false;
        _applyFilters(query ?? _searchController.text);
        if (_filteredOffenseList.isEmpty) {
          _errorMessage = query?.isNotEmpty ??
                  false || (_startDate != null && _endDate != null)
              ? '未找到符合条件的违法信息'
              : '当前没有违法记录';
        }
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Navigator.pushReplacementNamed(context, Routes.login);
        } else if (e.toString().contains('404')) {
          _offenseList.clear();
          _filteredOffenseList.clear();
          _errorMessage = '未找到违法记录';
          _hasMore = false;
        } else {
          _errorMessage = '获取违法信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return [];
      }
      switch (_searchType) {
        case 'driverName':
          final offenses = await offenseApi.apiOffensesByDriverNameGet(
              query: prefix.trim(), page: 1, size: 10);
          return offenses
              .map((o) => o.driverName ?? '')
              .where(
                  (name) => name.toLowerCase().contains(prefix.toLowerCase()))
              .toList();
        case 'licensePlate':
          final offenses = await offenseApi.apiOffensesByLicensePlateGet(
              query: prefix.trim(), page: 1, size: 10);
          return offenses
              .map((o) => o.licensePlate ?? '')
              .where(
                  (plate) => plate.toLowerCase().contains(prefix.toLowerCase()))
              .toList();
        case 'offenseType':
          final offenses = await offenseApi.apiOffensesByOffenseTypeGet(
              query: prefix.trim(), page: 1, size: 10);
          return offenses
              .map((o) => o.offenseType ?? '')
              .where(
                  (type) => type.toLowerCase().contains(prefix.toLowerCase()))
              .toList();
        default:
          return [];
      }
    } catch (e) {
      setState(() => _errorMessage = '获取建议失败: $e');
      return [];
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredOffenseList.clear();
      _filteredOffenseList = _offenseList.where((offense) {
        final driverName = (offense.driverName ?? '').toLowerCase();
        final licensePlate = (offense.licensePlate ?? '').toLowerCase();
        final offenseType = (offense.offenseType ?? '').toLowerCase();
        final offenseTime = offense.offenseTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'driverName') {
            matchesQuery = driverName.contains(searchQuery);
          } else if (_searchType == 'licensePlate') {
            matchesQuery = licensePlate.contains(searchQuery);
          } else if (_searchType == 'offenseType') {
            matchesQuery = offenseType.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null && offenseTime != null) {
          matchesDateRange = offenseTime.isAfter(_startDate!) &&
              offenseTime.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null &&
            _endDate != null &&
            offenseTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredOffenseList.isEmpty && _offenseList.isNotEmpty) {
        _errorMessage = '未找到符合条件的违法信息';
      } else {
        _errorMessage = _filteredOffenseList.isEmpty && _offenseList.isEmpty
            ? '当前没有违法记录'
            : '';
      }
    });
  }

  // ignore: unused_element
  Future<void> _searchOffenses() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  Future<void> _refreshOffenses({String? query}) async {
    setState(() {
      _offenseList.clear();
      _filteredOffenseList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startDate = null;
        _endDate = null;
        _searchType = 'driverName';
      }
    });
    await _fetchOffenses(reset: true, query: query);
  }

  Future<void> _loadMoreOffenses() async {
    if (!_isLoading && _hasMore) {
      await _fetchOffenses();
    }
  }

  void _createOffense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddOffensePage()),
    ).then((value) {
      if (value == true) {
        _refreshOffenses();
      }
    });
  }

  void _editOffense(OffenseInformation offense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOffensePage(offense: offense),
      ),
    ).then((value) {
      if (value == true) {
        _refreshOffenses();
      }
    });
  }

  void _goToDetailPage(OffenseInformation offense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OffenseDetailPage(offense: offense),
      ),
    );
  }

  Future<void> _deleteOffense(int offenseId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此违法信息吗？此操作不可撤销。'),
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
          Navigator.pushReplacementNamed(context, Routes.login);
          return;
        }
        await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
        await _refreshOffenses();
      } catch (e) {
        setState(() => _errorMessage = '删除违法信息失败: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
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
                    if (textEditingValue.text.isEmpty) {
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
                        hintText: _searchType == 'driverName'
                            ? '搜索司机姓名'
                            : _searchType == 'licensePlate'
                                ? '搜索车牌号'
                                : '搜索违法类型',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search,
                            color: themeData.colorScheme.primary),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color:
                                        themeData.colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  controller.clear();
                                  _searchController.clear();
                                  _applyFilters('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
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
                    _startDate = null;
                    _endDate = null;
                    _applyFilters('');
                  });
                },
                items: <String>['driverName', 'licensePlate', 'offenseType']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'driverName'
                          ? '按司机姓名'
                          : value == 'licensePlate'
                              ? '按车牌号'
                              : '按违法类型',
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
                  _startDate != null && _endDate != null
                      ? '违法时间范围: ${formatDate(_startDate)} 至 ${formatDate(_endDate)}'
                      : '选择违法时间范围',
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: _startDate != null && _endDate != null
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.date_range,
                    color: themeData.colorScheme.primary),
                tooltip: '按违法时间范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择违法时间范围',
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
                      _startDate = range.start;
                      _endDate = range.end;
                    });
                    _applyFilters(_searchController.text);
                  }
                },
              ),
              if (_startDate != null && _endDate != null)
                IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  tooltip: '清除日期范围',
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
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
        return DashboardPageTemplate(
        theme: themeData,
        title: '违法行为管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isAdmin) ...[
            DashboardPageBarAction(
              icon: Icons.add,
              onPressed: _createOffense,
              tooltip: '添加违法信息',
            ),
            DashboardPageBarAction(
              icon: Icons.refresh,
              onPressed: () => _refreshOffenses(),
              tooltip: '刷新列表',
            ),
          ],
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: RefreshIndicator(
          onRefresh: () => _refreshOffenses(),
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
                        _loadMoreOffenses();
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
                                _filteredOffenseList.isEmpty
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
                                              Navigator.pushReplacementNamed(
                                                  context, Routes.login),
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
                                itemCount: _filteredOffenseList.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredOffenseList.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final offense = _filteredOffenseList[index];
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
                                        '违法类型: ${offense.offenseType ?? '未知类型'}',
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
                                            '车牌号: ${offense.licensePlate ?? '未知车牌'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '司机姓名: ${offense.driverName ?? '未知司机'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '状态: ${offense.processStatus ?? '无'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: _isAdmin
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 18),
                                                  color: themeData
                                                      .colorScheme.primary,
                                                  onPressed: () =>
                                                      _editOffense(offense),
                                                  tooltip: '编辑违法信息',
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete,
                                                      size: 18,
                                                      color: themeData
                                                          .colorScheme.error),
                                                  onPressed: () =>
                                                      _deleteOffense(
                                                          offense.offenseId ??
                                                              0),
                                                  tooltip: '删除违法信息',
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: themeData.colorScheme
                                                      .onSurfaceVariant,
                                                  size: 18,
                                                ),
                                              ],
                                            )
                                          : Icon(
                                              Icons.arrow_forward_ios,
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                              size: 18,
                                            ),
                                      onTap: () => _goToDetailPage(offense),
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

class AddOffensePage extends StatefulWidget {
  const AddOffensePage({super.key});

  @override
  State<AddOffensePage> createState() => _AddOffensePageState();
}

class _AddOffensePageState extends State<AddOffensePage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi(); // Add vehicle API
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _offenseTypeController = TextEditingController();
  final _offenseCodeController = TextEditingController();
  final _offenseLocationController = TextEditingController();
  final _offenseTimeController = TextEditingController();
  final _deductedPointsController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _processStatusController = TextEditingController();
  final _processResultController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
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
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      await offenseApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt(); // Initialize vehicle API
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    _offenseTypeController.dispose();
    _offenseCodeController.dispose();
    _offenseLocationController.dispose();
    _offenseTimeController.dispose();
    _deductedPointsController.dispose();
    _fineAmountController.dispose();
    _processStatusController.dispose();
    _processResultController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchDriverNameSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return [];
      }
      final vehicles = await vehicleApi.apiVehiclesSearchGeneralGet(
          keywords: prefix, page: 1, size: 10);
      return vehicles
          .map((v) => v.ownerName ?? '')
          .where((name) => name.toLowerCase().contains(prefix.toLowerCase()))
          .toSet()
          .toList();
    } catch (e) {
      _showSnackBar('获取司机姓名建议失败: $e', isError: true);
      return [];
    }
  }

  Future<List<String>> _fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return [];
      }
      return await vehicleApi.apiVehiclesSearchLicenseGlobalGet(prefix: prefix);
    } catch (e) {
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<void> _submitOffense() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final offenseTime =
          DateTime.parse("${_offenseTimeController.text.trim()}T00:00:00.000");
      final idempotencyKey = generateIdempotencyKey();
      final offensePayload = OffenseInformation(
        offenseTime: offenseTime,
        driverName: _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim(),
        deductedPoints: _deductedPointsController.text.trim().isEmpty
            ? null
            : int.parse(_deductedPointsController.text.trim()),
        fineAmount: _fineAmountController.text.trim().isEmpty
            ? null
            : double.parse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim().isEmpty
            ? 'Pending'
            : _processStatusController.text.trim(),
        processResult: _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
        idempotencyKey: idempotencyKey,
      );
      await offenseApi.apiOffensesPost(
        offenseInformation: offensePayload,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('创建违法行为记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建违法行为记录失败: $e', isError: true);
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value.copyWith(
          colorScheme: controller.currentBodyTheme.value.colorScheme.copyWith(
            primary: controller.currentBodyTheme.value.colorScheme.primary,
            onPrimary: controller.currentBodyTheme.value.colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() => _offenseTimeController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator}) {
    if (label == '司机姓名' || label == '车牌号') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return label == '司机姓名'
                ? await _fetchDriverNameSuggestions(textEditingValue.text)
                : await _fetchLicensePlateSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
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
                        .withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
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
                    if (label == '司机姓名' && trimmedValue.length > 100) {
                      return '司机姓名不能超过100个字符';
                    }
                    if (label == '车牌号') {
                      if (trimmedValue.isEmpty) return '车牌号不能为空';
                      if (trimmedValue.length > 20) return '车牌号不能超过20个字符';
                      if (!isValidLicensePlate(trimmedValue)) {
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
          helperText: label == '违法地点'
              ? '请输入违法地点，例如：XX路口'
              : label == '车牌号'
                  ? '请输入车牌号，例如：黑AWS34'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
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
              if (label == '违法类型' && trimmedValue.length > 100) {
                return '违法类型不能超过100个字符';
              }
              if (label == '违法代码' && trimmedValue.length > 50) {
                return '违法代码不能超过50个字符';
              }
              if (label == '违法地点' && trimmedValue.length > 100) {
                return '违法地点不能超过100个字符';
              }
              if (label == '违法时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '违法时间不能晚于当前日期';
                }
              }
              if (label == '扣分' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分必须是整数';
                if (points < 0) return '扣分不能为负数';
                if (points > 12) return '扣分不能超过12分';
              }
              if (label == '罚款金额' && trimmedValue.isNotEmpty) {
                final amount = num.tryParse(trimmedValue);
                if (amount == null) return '罚款金额必须是数字';
                if (amount < 0) return '罚款金额不能为负数';
                if (amount > 99999999.99) return '罚款金额不能超过99999999.99';
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmedValue)) {
                  return '罚款金额最多保留两位小数';
                }
              }
              if (label == '处理状态' && trimmedValue.length > 50) {
                return '处理状态不能超过50个字符';
              }
              if (label == '处理结果' && trimmedValue.length > 255) {
                return '处理结果不能超过255个字符';
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
        return DashboardPageTemplate(
        theme: themeData,
        title: '添加新违法行为',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
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
                                    '司机姓名', _driverNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '车牌号', _licensePlateController, themeData,
                                    required: true, maxLength: 20),
                                _buildTextField(
                                    '违法类型', _offenseTypeController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '违法代码', _offenseCodeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField('违法地点',
                                    _offenseLocationController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '违法时间', _offenseTimeController, themeData,
                                    required: true,
                                    readOnly: true,
                                    onTap: _pickDate),
                                _buildTextField(
                                    '扣分', _deductedPointsController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true)),
                                _buildTextField(
                                    '处理状态', _processStatusController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '处理结果', _processResultController, themeData,
                                    maxLength: 255),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitOffense,
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

class OffenseDetailPage extends StatefulWidget {
  final OffenseInformation offense;

  const OffenseDetailPage({super.key, required this.offense});

  @override
  State<OffenseDetailPage> createState() => _OffenseDetailPageState();
}

class _OffenseDetailPageState extends State<OffenseDetailPage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
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
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      await offenseApi.initializeWithJwt();
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
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isEditable = roles.contains('ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteOffense(int offenseId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此违法信息吗？此操作不可撤销。'),
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
          Navigator.pushReplacementNamed(context, Routes.login);
          return;
        }
        await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
        _showSnackBar('删除违法信息成功！');
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
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

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: themeData.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          Expanded(
            child: Text(value,
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
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
                return DashboardPageTemplate(
          theme: themeData,
          title: '违法行为详情',
          pageType: DashboardPageType.manager,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage,
                    style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.error,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                if (_errorMessage.contains('登录'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, Routes.login),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary),
                      child: const Text('前往登录'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

        return DashboardPageTemplate(
        theme: themeData,
        title: '违法行为详情',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isEditable) ...[
            DashboardPageBarAction(
              icon: Icons.edit,
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EditOffensePage(offense: widget.offense)))
                    .then((value) {
                  if (value == true && mounted) {
                    Navigator.pop(context, true);
                  }
                });
              },
              tooltip: '编辑违法信息',
            ),
            DashboardPageBarAction(
              icon: Icons.delete,
              color: themeData.colorScheme.error,
              onPressed: () => _deleteOffense(widget.offense.offenseId!),
              tooltip: '删除违法信息',
            ),
          ],
        ],
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
                          _buildDetailRow('司机姓名',
                              widget.offense.driverName ?? '未知', themeData),
                          _buildDetailRow('车牌号',
                              widget.offense.licensePlate ?? '未知', themeData),
                          _buildDetailRow('违法类型',
                              widget.offense.offenseType ?? '未知', themeData),
                          _buildDetailRow('违法代码',
                              widget.offense.offenseCode ?? '无', themeData),
                          _buildDetailRow('违法地点',
                              widget.offense.offenseLocation ?? '无', themeData),
                          _buildDetailRow(
                              '违法时间',
                              formatDate(widget.offense.offenseTime),
                              themeData),
                          _buildDetailRow(
                              '扣分',
                              widget.offense.deductedPoints?.toString() ?? '无',
                              themeData),
                          _buildDetailRow(
                              '罚款金额',
                              widget.offense.fineAmount?.toString() ?? '无',
                              themeData),
                          _buildDetailRow('处理状态',
                              widget.offense.processStatus ?? '无', themeData),
                          _buildDetailRow('处理结果',
                              widget.offense.processResult ?? '无', themeData),
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

class EditOffensePage extends StatefulWidget {
  final OffenseInformation offense;

  const EditOffensePage({super.key, required this.offense});

  @override
  State<EditOffensePage> createState() => _EditOffensePageState();
}

class _EditOffensePageState extends State<EditOffensePage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi(); // Add vehicle API
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _offenseTypeController = TextEditingController();
  final _offenseCodeController = TextEditingController();
  final _offenseLocationController = TextEditingController();
  final _offenseTimeController = TextEditingController();
  final _deductedPointsController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _processStatusController = TextEditingController();
  final _processResultController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();

  Future<bool> _validateJwtToken() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
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
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }
      await offenseApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt(); // Initialize vehicle API
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    setState(() {
      _driverNameController.text = widget.offense.driverName ?? '';
      _licensePlateController.text = widget.offense.licensePlate ?? '';
      _offenseTypeController.text = widget.offense.offenseType ?? '';
      _offenseCodeController.text = widget.offense.offenseCode ?? '';
      _offenseLocationController.text = widget.offense.offenseLocation ?? '';
      _offenseTimeController.text = formatDate(widget.offense.offenseTime);
      _deductedPointsController.text =
          widget.offense.deductedPoints?.toString() ?? '';
      _fineAmountController.text = widget.offense.fineAmount?.toString() ?? '';
      _processStatusController.text = widget.offense.processStatus ?? '';
      _processResultController.text = widget.offense.processResult ?? '';
    });
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    _offenseTypeController.dispose();
    _offenseCodeController.dispose();
    _offenseLocationController.dispose();
    _offenseTimeController.dispose();
    _deductedPointsController.dispose();
    _fineAmountController.dispose();
    _processStatusController.dispose();
    _processResultController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchDriverNameSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return [];
      }
      final vehicles = await vehicleApi.apiVehiclesSearchGeneralGet(
          keywords: prefix, page: 1, size: 10);
      return vehicles
          .map((v) => v.ownerName ?? '')
          .where((name) => name.toLowerCase().contains(prefix.toLowerCase()))
          .toSet()
          .toList();
    } catch (e) {
      _showSnackBar('获取司机姓名建议失败: $e', isError: true);
      return [];
    }
  }

  Future<List<String>> _fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return [];
      }
      return await vehicleApi.apiVehiclesSearchLicenseGlobalGet(prefix: prefix);
    } catch (e) {
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<void> _updateOffense() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final offenseTime =
          DateTime.parse("${_offenseTimeController.text.trim()}T00:00:00.000");
      final offensePayload = OffenseInformation(
        offenseId: widget.offense.offenseId,
        driverName: _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim(),
        offenseTime: offenseTime,
        deductedPoints: _deductedPointsController.text.trim().isEmpty
            ? null
            : int.parse(_deductedPointsController.text.trim()),
        fineAmount: _fineAmountController.text.trim().isEmpty
            ? null
            : double.parse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim().isEmpty
            ? 'Pending'
            : _processStatusController.text.trim(),
        processResult: _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
      );
      final idempotencyKey = generateIdempotencyKey();
      await offenseApi.apiOffensesOffenseIdPut(
        offenseId: widget.offense.offenseId!,
        offenseInformation: offensePayload,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('更新违法行为记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新违法行为记录失败: $e', isError: true);
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.offense.offenseTime ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value.copyWith(
          colorScheme: controller.currentBodyTheme.value.colorScheme.copyWith(
            primary: controller.currentBodyTheme.value.colorScheme.primary,
            onPrimary: controller.currentBodyTheme.value.colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() => _offenseTimeController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator}) {
    if (label == '司机姓名' || label == '车牌号') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return label == '司机姓名'
                ? await _fetchDriverNameSuggestions(textEditingValue.text)
                : await _fetchLicensePlateSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
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
                        .withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
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
                    if (label == '司机姓名' && trimmedValue.length > 100) {
                      return '司机姓名不能超过100个字符';
                    }
                    if (label == '车牌号') {
                      if (trimmedValue.isEmpty) return '车牌号不能为空';
                      if (trimmedValue.length > 20) return '车牌号不能超过20个字符';
                      if (!isValidLicensePlate(trimmedValue)) {
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
          helperText: label == '违法地点'
              ? '请输入违法地点，例如：XX路口'
              : label == '车牌号'
                  ? '请输入车牌号，例如：黑AWS34'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
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
              if (label == '违法类型' && trimmedValue.length > 100) {
                return '违法类型不能超过100个字符';
              }
              if (label == '违法代码' && trimmedValue.length > 50) {
                return '违法代码不能超过50个字符';
              }
              if (label == '违法地点' && trimmedValue.length > 100) {
                return '违法地点不能超过100个字符';
              }
              if (label == '违法时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '违法时间不能晚于当前日期';
                }
              }
              if (label == '扣分' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分必须是整数';
                if (points < 0) return '扣分不能为负数';
                if (points > 12) return '扣分不能超过12分';
              }
              if (label == '罚款金额' && trimmedValue.isNotEmpty) {
                final amount = num.tryParse(trimmedValue);
                if (amount == null) return '罚款金额必须是数字';
                if (amount < 0) return '罚款金额不能为负数';
                if (amount > 99999999.99) return '罚款金额不能超过99999999.99';
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmedValue)) {
                  return '罚款金额最多保留两位小数';
                }
              }
              if (label == '处理状态' && trimmedValue.length > 50) {
                return '处理状态不能超过50个字符';
              }
              if (label == '处理结果' && trimmedValue.length > 255) {
                return '处理结果不能超过255个字符';
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
        return DashboardPageTemplate(
        theme: themeData,
        title: '编辑违法行为信息',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
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
                                    '司机姓名', _driverNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '车牌号', _licensePlateController, themeData,
                                    required: true, maxLength: 20),
                                _buildTextField(
                                    '违法类型', _offenseTypeController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '违法代码', _offenseCodeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField('违法地点',
                                    _offenseLocationController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '违法时间', _offenseTimeController, themeData,
                                    required: true,
                                    readOnly: true,
                                    onTap: _pickDate),
                                _buildTextField(
                                    '扣分', _deductedPointsController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true)),
                                _buildTextField(
                                    '处理状态', _processStatusController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '处理结果', _processResultController, themeData,
                                    maxLength: 255),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateOffense,
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
