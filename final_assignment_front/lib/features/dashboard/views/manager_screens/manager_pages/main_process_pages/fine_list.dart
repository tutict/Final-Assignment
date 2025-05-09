import 'dart:convert';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 格式化日期的全局方法
String formatDate(DateTime? date) {
  if (date == null) return '无';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

/// FineList 页面：管理员才能访问
class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListState();
}

class _FineListState extends State<FineList> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<FineInformation> _fineList = [];
  List<FineInformation> _filteredFineList = [];
  String _searchType = 'payee';
  int _currentPage = 1;
  final int _pageSize = 20;
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
        await fineApi.initializeWithJwt();
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
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
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
      await _fetchFines(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
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

  Future<void> _fetchFines({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _fineList.clear();
      _filteredFineList.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      List<FineInformation> fines = [];
      final searchQuery = query?.trim() ?? '';
      if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
        fines = await fineApi.apiFinesGet() ?? [];
      } else if (_searchType == 'payee' && searchQuery.isNotEmpty) {
        fines = await fineApi.apiFinesPayeePayeeGet(payee: searchQuery) ?? [];
      } else if (_searchType == 'timeRange' &&
          _startDate != null &&
          _endDate != null) {
        fines = await fineApi.apiFinesTimeRangeGet(
              startTime: _startDate!.toIso8601String(),
              endTime: _endDate!.add(const Duration(days: 1)).toIso8601String(),
            ) ??
            [];
      }

      setState(() {
        _fineList.addAll(fines);
        _hasMore = fines.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredFineList.isEmpty) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startDate != null && _endDate != null)
                  ? '未找到符合条件的罚款信息'
                  : '当前没有罚款记录';
        }
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Navigator.pushReplacementNamed(context, AppPages.login);
        } else if (e.toString().contains('404')) {
          _fineList.clear();
          _filteredFineList.clear();
          _errorMessage = '未找到罚款记录';
          _hasMore = false;
        } else {
          _errorMessage = '获取罚款信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      if (_searchType == 'payee') {
        final fines = await fineApi.apiFinesPayeePayeeGet(payee: prefix.trim());
        return fines
                ?.map((fine) => fine.payee ?? '')
                .where((payee) =>
                    payee.toLowerCase().contains(prefix.toLowerCase()))
                .take(5)
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      setState(() => _errorMessage = '获取建议失败: $e');
      return [];
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredFineList.clear();
      _filteredFineList = _fineList.where((fine) {
        final payee = (fine.payee ?? '').toLowerCase();
        final fineTime =
            fine.fineTime != null ? DateTime.parse(fine.fineTime!) : null;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty && _searchType == 'payee') {
          matchesQuery = payee.contains(searchQuery);
        }

        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null && fineTime != null) {
          matchesDateRange = fineTime.isAfter(_startDate!) &&
              fineTime.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null && _endDate != null && fineTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredFineList.isEmpty && _fineList.isNotEmpty) {
        _errorMessage = '未找到符合条件的罚款信息';
      } else {
        _errorMessage =
            _filteredFineList.isEmpty && _fineList.isEmpty ? '当前没有罚款记录' : '';
      }
    });
  }

  Future<void> _searchFines() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  Future<void> _refreshFines({String? query}) async {
    setState(() {
      _fineList.clear();
      _filteredFineList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startDate = null;
        _endDate = null;
        _searchType = 'payee';
      }
    });
    await _fetchFines(reset: true, query: query);
  }

  Future<void> _loadMoreFines() async {
    if (!_isLoading && _hasMore) {
      await _fetchFines();
    }
  }

  void _createFine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFinePage()),
    ).then((value) {
      if (value == true) {
        _refreshFines();
      }
    });
  }

  void _goToDetailPage(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FineDetailPage(fine: fine)),
    ).then((value) {
      if (value == true) {
        _refreshFines();
      }
    });
  }

  Future<void> _deleteFine(int fineId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此罚款信息吗？此操作不可撤销。'),
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
          Navigator.pushReplacementNamed(context, AppPages.login);
          return;
        }
        await fineApi.apiFinesFineIdDelete(fineId: fineId);
        _showSnackBar('删除罚款成功！');
        await _refreshFines();
      } catch (e) {
        _showSnackBar('删除罚款失败: $e', isError: true);
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
                        _searchType != 'payee') {
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
                        hintText:
                            _searchType == 'payee' ? '搜索缴款人' : '搜索时间范围（已选择）',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search,
                            color: themeData.colorScheme.primary),
                        suffixIcon: controller.text.isNotEmpty ||
                                (_startDate != null && _endDate != null)
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color:
                                        themeData.colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  controller.clear();
                                  _searchController.clear();
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                    _searchType = 'payee';
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
                      enabled: _searchType == 'payee',
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
                items: <String>['payee', 'timeRange']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'payee' ? '按缴款人' : '按时间范围',
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
                      ? '罚款日期范围: ${formatDate(_startDate)} 至 ${formatDate(_endDate)}'
                      : '选择罚款日期范围',
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
                tooltip: '按罚款日期范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择罚款日期范围',
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
                      _searchType = 'timeRange';
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
                      _searchType = 'payee';
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
            '罚款管理',
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
                onPressed: _createFine,
                tooltip: '添加罚款信息',
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              IconButton(
                icon: Icon(Icons.refresh,
                    color: themeData.colorScheme.onPrimaryContainer, size: 24),
                onPressed: () => _refreshFines(),
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
          onRefresh: () => _refreshFines(),
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
                        _loadMoreFines();
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
                        : _errorMessage.isNotEmpty && _filteredFineList.isEmpty
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
                                                  context, AppPages.login),
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
                                itemCount: _filteredFineList.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredFineList.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final fine = _filteredFineList[index];
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
                                        '金额: ${fine.fineAmount ?? 0} 元',
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
                                            '缴款人: ${fine.payee ?? '未知'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '时间: ${formatDate(fine.fineTime != null ? DateTime.parse(fine.fineTime!) : null)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '状态: ${fine.status ?? 'Pending'}',
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
                                            icon: Icon(Icons.delete,
                                                size: 18,
                                                color: themeData
                                                    .colorScheme.error),
                                            onPressed: () =>
                                                _deleteFine(fine.fineId ?? 0),
                                            tooltip: '删除罚款',
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _goToDetailPage(fine),
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

class AddFinePage extends StatefulWidget {
  const AddFinePage({super.key});

  @override
  State<AddFinePage> createState() => _AddFinePageState();
}

class _AddFinePageState extends State<AddFinePage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();
  int? _selectedOffenseId;

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
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _fineAmountController.dispose();
    _payeeController.dispose();
    _accountNumberController.dispose();
    _bankController.dispose();
    _receiptNumberController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      return await vehicleApi.apiVehiclesLicensePlateGloballyGet(
          licensePlate: prefix);
    } catch (e) {
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<List<String>> _fetchPayeeSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: _plateNumberController.text.trim(),
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        return offenses
            .map((o) => o.driverName ?? '')
            .where((name) => name.toLowerCase().contains(prefix.toLowerCase()))
            .toSet()
            .toList();
      }
      final vehicles = await vehicleApi.apiVehiclesSearchGet(
          query: prefix, page: 1, size: 10);
      return vehicles
          .map((v) => v.ownerName ?? '')
          .where((name) => name.toLowerCase().contains(prefix.toLowerCase()))
          .toSet()
          .toList();
    } catch (e) {
      _showSnackBar('获取缴款人建议失败: $e', isError: true);
      return [];
    }
  }

  Future<void> _onLicensePlateSelected(String licensePlate) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        final latestOffense = offenses.first;
        setState(() {
          _selectedOffenseId = latestOffense.offenseId;
          _payeeController.text = latestOffense.driverName ?? '';
          _fineAmountController.text =
              latestOffense.fineAmount?.toString() ?? '';
        });
      } else {
        _showSnackBar('未找到与此车牌相关的违法记录', isError: true);
        setState(() {
          _selectedOffenseId = null;
          _payeeController.clear();
          _fineAmountController.clear();
        });
      }
    } catch (e) {
      _showSnackBar('获取违法信息失败: $e', isError: true);
    }
  }

  Future<void> _submitFine() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final finePayload = FineInformation(
        offenseId: _selectedOffenseId ?? 0,
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        bank: _bankController.text.trim().isEmpty
            ? null
            : _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim().isEmpty
            ? null
            : _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        fineTime: _dateController.text.isNotEmpty
            ? DateTime.parse("${_dateController.text.trim()}T00:00:00.000")
                .toIso8601String()
            : null,
        status: 'Pending',
        idempotencyKey: idempotencyKey,
      );
      await fineApi.apiFinesPost(
        fineInformation: finePayload,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('创建罚款成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建罚款失败: $e', isError: true);
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
      setState(() => _dateController.text = formatDate(pickedDate));
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
    if (label == '车牌号' || label == '缴款人') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return label == '车牌号'
                ? await _fetchLicensePlateSuggestions(textEditingValue.text)
                : await _fetchPayeeSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) async {
            controller.text = selection;
            if (label == '车牌号') {
              await _onLicensePlateSelected(selection);
            }
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
                              _payeeController.clear();
                              _fineAmountController.clear();
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
                    if (label == '缴款人' && trimmedValue.length > 100) {
                      return '缴款人姓名不能超过100个字符';
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
          helperText: label == '银行账号' ? '请输入银行账号（选填）' : null,
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
              if (label == '罚款金额' && trimmedValue.isNotEmpty) {
                final amount = num.tryParse(trimmedValue);
                if (amount == null) return '罚款金额必须是数字';
                if (amount < 0) return '罚款金额不能为负数';
                if (amount > 99999999.99) return '罚款金额不能超过99999999.99';
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmedValue)) {
                  return '罚款金额最多保留两位小数';
                }
              }
              if (label == '银行账号' && trimmedValue.length > 50) {
                return '银行账号不能超过50个字符';
              }
              if (label == '银行名称' && trimmedValue.length > 100) {
                return '银行名称不能超过100个字符';
              }
              if (label == '收据编号' && trimmedValue.length > 50) {
                return '收据编号不能超过50个字符';
              }
              if (label == '备注' && trimmedValue.length > 255) {
                return '备注不能超过255个字符';
              }
              if (label == '罚款日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '罚款日期不能晚于当前日期';
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
          title: Text('添加新罚款',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
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
                                    '车牌号', _plateNumberController, themeData,
                                    required: true, maxLength: 20),
                                _buildTextField(
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    required: true),
                                _buildTextField(
                                    '缴款人', _payeeController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '银行账号', _accountNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '银行名称', _bankController, themeData,
                                    maxLength: 100),
                                _buildTextField(
                                    '收据编号', _receiptNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '备注', _remarksController, themeData,
                                    maxLength: 255),
                                _buildTextField(
                                    '罚款日期', _dateController, themeData,
                                    readOnly: true,
                                    onTap: _pickDate,
                                    required: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitFine,
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

/// 罚款详情页面
class FineDetailPage extends StatefulWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  State<FineDetailPage> createState() => _FineDetailPageState();
}

class _FineDetailPageState extends State<FineDetailPage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
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
      final decodedToken = JwtDecoder.decode(jwtToken);
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
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
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
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
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
        setState(() => _isAdmin = roles.contains('ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final idempotencyKey = generateIdempotencyKey();
      final finePayload = {
        'fineId': fineId,
        'status': status,
        'fineTime': DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/fines/$fineId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(finePayload),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update fine status: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('罚款记录已${status == 'Approved' ? '批准' : '拒绝'}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新状态失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此罚款信息吗？此操作不可撤销。'),
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
          Navigator.pushReplacementNamed(context, AppPages.login);
          return;
        }
        await fineApi.apiFinesFineIdDelete(fineId: fineId);
        _showSnackBar('罚款删除成功！');
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
        return Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage,
                    style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.error,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                if (_errorMessage.contains('未授权') ||
                    _errorMessage.contains('登录'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppPages.login),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary),
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
          title: Text('罚款详情',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isAdmin
              ? [
                  if (widget.fine.status == 'Pending') ...[
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => _updateFineStatus(
                          widget.fine.fineId ?? 0, 'Approved'),
                      tooltip: '批准罚款',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _updateFineStatus(
                          widget.fine.fineId ?? 0, 'Rejected'),
                      tooltip: '拒绝罚款',
                    ),
                  ],
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: () => _deleteFine(widget.fine.fineId ?? 0),
                    tooltip: '删除罚款',
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
                          _buildDetailRow('罚款金额',
                              '${widget.fine.fineAmount ?? 0} 元', themeData),
                          _buildDetailRow(
                              '缴款人', widget.fine.payee ?? '未知', themeData),
                          _buildDetailRow(
                              '罚款时间',
                              formatDate(widget.fine.fineTime != null
                                  ? DateTime.parse(widget.fine.fineTime!)
                                  : null),
                              themeData),
                          _buildDetailRow('银行账号',
                              widget.fine.accountNumber ?? '无', themeData),
                          _buildDetailRow(
                              '银行名称', widget.fine.bank ?? '无', themeData),
                          _buildDetailRow('收据编号',
                              widget.fine.receiptNumber ?? '无', themeData),
                          _buildDetailRow(
                              '状态', widget.fine.status ?? 'Pending', themeData),
                          _buildDetailRow(
                              '备注', widget.fine.remarks ?? '无', themeData),
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
