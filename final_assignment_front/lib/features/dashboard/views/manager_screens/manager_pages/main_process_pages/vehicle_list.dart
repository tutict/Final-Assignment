import 'dart:convert';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Utility methods for validation
bool isValidLicensePlate(String value) {
  final regex = RegExp(r'^[\u4e00-\u9fa5][A-Za-z][A-Za-z0-9]{5,6}$');
  return regex.hasMatch(value);
}

bool isValidIdCardNumber(String value) {
  final regex = RegExp(r'^\d{15}$|^\d{17}[\dX]$');
  return regex.hasMatch(value);
}

bool isValidPhoneNumber(String value) {
  final regex = RegExp(r'^1[3-9]\d{9}$');
  return regex.hasMatch(value);
}

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return '未设置';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  final DashboardController controller = Get.find<DashboardController>();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<VehicleInformation> _vehicleList = [];
  List<VehicleInformation> _filteredVehicleList = [];
  String _searchType = 'licensePlate';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startDate;
  DateTime? _endDate;

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
    debugPrint('Retrieved JWT: $jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      debugPrint('JWT token not found or empty');
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      debugPrint('Decoded JWT: $decodedToken');
      if (JwtDecoder.isExpired(jwtToken)) {
        debugPrint('JWT token is expired: ${decodedToken['exp']}');
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await prefs.setString('jwtToken', jwtToken);
        final newDecodedToken = JwtDecoder.decode(jwtToken);
        debugPrint('New JWT decoded: $newDecodedToken');
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await vehicleApi.initializeWithJwt();
      }
      debugPrint('JWT token is valid. Subject: ${decodedToken['sub']}');
      return true;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      debugPrint('Refresh token not found');
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
        debugPrint('Refreshed JWT: $newJwt');
        return newJwt;
      }
      debugPrint(
          'Failed to refresh JWT: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.initializeWithJwt(); // 确保初始化 JWT
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN'; // 修正字段名
      await _checkUserRole();
      await _fetchVehicles(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
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
            (JwtDecoder.decode(jwtToken)['roles'] is String
                ? [JwtDecoder.decode(jwtToken)['roles']]
                : []);
        debugPrint('User roles from /api/users/me: $roles');
        debugPrint('Full userData: $userData');
        setState(() => _isAdmin = roles.contains('ADMIN')); // Changed to ADMIN
      } else {
        debugPrint(
            'Role check failed: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking role: $e');
      setState(() => _errorMessage = '验证角色失败: $e');
    }
  }

  Future<void> _fetchVehicles({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _vehicleList.clear();
      _filteredVehicleList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      List<VehicleInformation> vehicles =
          await vehicleApi.apiVehiclesGet(); // 无分页参数

      setState(() {
        _vehicleList.addAll(vehicles);
        _hasMore = false; // 后端返回全量数据，无需分页
        _applyFilters(query ?? _searchController.text);
        if (_filteredVehicleList.isEmpty) {
          _errorMessage = query?.isNotEmpty ??
                  false || (_startDate != null && _endDate != null)
              ? '未找到符合条件的车辆'
              : '当前没有车辆记录';
        }
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Navigator.pushReplacementNamed(context, '/login');
        } else if (e.toString().contains('404')) {
          _vehicleList.clear();
          _filteredVehicleList.clear();
          _errorMessage = '未找到车辆记录';
          _hasMore = false;
        } else {
          _errorMessage = '获取车辆信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return [];
      }
      if (_searchType == 'licensePlate') {
        final suggestions = await vehicleApi.apiVehiclesLicensePlateGloballyGet(
          licensePlate: prefix,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      } else {
        final suggestions = await vehicleApi.apiVehiclesTypeGloballyGet(
          vehicleType: prefix,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      }
    } catch (e) {
      setState(() => _errorMessage = '获取建议失败: $e');
      return [];
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredVehicleList.clear();
      _filteredVehicleList = _vehicleList.where((vehicle) {
        final licensePlate = (vehicle.licensePlate ?? '').toLowerCase();
        final vehicleType = (vehicle.vehicleType ?? '').toLowerCase();
        final registrationDate = vehicle.firstRegistrationDate;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'licensePlate') {
            matchesQuery = licensePlate.contains(searchQuery);
          } else if (_searchType == 'vehicleType') {
            matchesQuery = vehicleType.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startDate != null &&
            _endDate != null &&
            registrationDate != null) {
          matchesDateRange = registrationDate.isAfter(_startDate!) &&
              registrationDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null &&
            _endDate != null &&
            registrationDate == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredVehicleList.isEmpty && _vehicleList.isNotEmpty) {
        _errorMessage = '未找到符合条件的车辆';
      } else {
        _errorMessage = _filteredVehicleList.isEmpty && _vehicleList.isEmpty
            ? '当前没有车辆记录'
            : '';
      }
    });
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  Future<void> _refreshVehicleList({String? query}) async {
    setState(() {
      _vehicleList.clear();
      _filteredVehicleList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startDate = null;
        _endDate = null;
        _searchType = 'licensePlate';
      }
    });
    await _fetchVehicles(reset: true, query: query);
  }

  Future<void> _loadMoreVehicles() async {
    if (!_isLoading && _hasMore) {
      await _fetchVehicles();
    }
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    );
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true) {
        _refreshVehicleList();
      }
    });
  }

  void _editVehicle(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(vehicle: vehicle),
      ),
    ).then((value) {
      if (value == true) {
        _refreshVehicleList();
      }
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此车辆信息吗？此操作不可撤销。'),
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
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
        await _refreshVehicleList();
      } catch (e) {
        setState(() {
          _errorMessage = '删除车辆失败: $e';
        });
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
                        hintText:
                            _searchType == 'licensePlate' ? '搜索车牌号' : '搜索车辆类型',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withOpacity(0.6)),
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
                items: <String>['licensePlate', 'vehicleType']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'licensePlate' ? '按车牌号' : '按车辆类型',
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
                      ? '首次注册日期: ${formatDate(_startDate)} 至 ${formatDate(_endDate)}'
                      : '选择首次注册日期范围',
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
                tooltip: '按首次注册日期范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择首次注册日期范围',
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
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '车辆管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            // Admin buttons (only shown for admins)
            if (_isAdmin) ...[
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: themeData.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                onPressed: _createVehicle,
                tooltip: '添加车辆',
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: themeData.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                onPressed: () => _refreshVehicleList(),
                tooltip: '刷新列表',
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
            ],
            // Theme toggle button
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
          onRefresh: () => _refreshVehicleList(),
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
                        _loadMoreVehicles();
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
                                _filteredVehicleList.isEmpty
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
                                                  context, '/login'),
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
                                itemCount: _filteredVehicleList.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredVehicleList.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final vehicle = _filteredVehicleList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      title: Text(
                                        '车牌号: ${vehicle.licensePlate ?? '未知车牌'}',
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
                                            '类型: ${vehicle.vehicleType ?? '未知类型'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '车主: ${vehicle.ownerName ?? '未知车主'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '状态: ${vehicle.currentStatus ?? '无'}',
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
                                                      _editVehicle(vehicle),
                                                  tooltip: '编辑车辆',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: themeData
                                                        .colorScheme.error,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteVehicle(
                                                          vehicle.vehicleId ??
                                                              0),
                                                  tooltip: '删除车辆',
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
                                      onTap: () => _goToDetailPage(vehicle),
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

class AddVehiclePage extends StatefulWidget {
  final VoidCallback? onVehicleAdded;

  const AddVehiclePage({super.key, this.onVehicleAdded});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
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
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      setState(() {
        _contactNumberController.text = '';
      });
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final licensePlate = '黑A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(licensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (await vehicleApi.apiVehiclesExistsGet(licensePlate: licensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }
    final idCardNumber = _idCardNumberController.text.trim();
    if (!isValidIdCardNumber(idCardNumber)) {
      _showSnackBar('身份证号码格式无效，请输入有效的15或18位身份证号码', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': null,
        'licensePlate': licensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': idCardNumber,
        'contactNumber': _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        'engineNumber': _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        'frameNumber': _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        'firstRegistrationDate': _firstRegistrationDateController.text.isEmpty
            ? null
            : '${_firstRegistrationDateController.text.trim()}T00:00:00.000',
        'currentStatus': _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      };
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/vehicles?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(vehiclePayload),
      );
      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create vehicle: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('创建车辆成功！');
      if (mounted) {
        Navigator.pop(context, true);
        widget.onVehicleAdded?.call();
      }
    } catch (e) {
      _showSnackBar('创建车辆失败: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix,
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
          helperText: label == '车牌号'
              ? '请输入车牌号后缀，例如：12345'
              : label == '身份证号码'
                  ? '请输入15或18位身份证号码'
                  : label == '联系电话'
                      ? '请输入11位手机号码'
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
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly && label == '首次录入车牌号的日期'
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
              if (label == '车牌号' && trimmedValue.isNotEmpty) {
                final fullPlate = '黑A$trimmedValue';
                if (fullPlate.length > 20) return '车牌号不能超过20个字符';
                if (!isValidLicensePlate(fullPlate)) {
                  return '车牌号格式无效（例如：黑A12345）';
                }
              }
              if (label == '车辆类型' && trimmedValue.length > 50) {
                return '车辆类型不能超过50个字符';
              }
              if (label == '车主姓名' && trimmedValue.length > 100) {
                return '车主姓名不能超过100个字符';
              }
              if (label == '身份证号码') {
                if (trimmedValue.isEmpty) return '身份证号码不能为空';
                if (trimmedValue.length > 18) {
                  return '身份证号码不能超过18个字符';
                }
                if (!isValidIdCardNumber(trimmedValue)) {
                  return '身份证号码格式无效';
                }
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) {
                  return '请输入有效的11位手机号码';
                }
              }
              if (label == '发动机号' && trimmedValue.length > 50) {
                return '发动机号不能超过50个字符';
              }
              if (label == '车架号' && trimmedValue.length > 50) {
                return '车架号不能超过50个字符';
              }
              if (label == '车身颜色' && trimmedValue.length > 50) {
                return '车身颜色不能超过50个字符';
              }
              if (label == '首次录入车牌号的日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '首次录入日期不能晚于当前日期';
                }
              }
              if (label == '当前状态' && trimmedValue.length > 50) {
                return '当前状态不能超过50个字符';
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
        appBar: widget.onVehicleAdded != null
            ? null
            : AppBar(
                title: Text('添加新车辆',
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
                                if (widget.onVehicleAdded != null)
                                  Text(
                                    '您当前没有车辆记录，请添加新车辆',
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold),
                                  ),
                                if (widget.onVehicleAdded != null)
                                  const SizedBox(height: 16),
                                _buildTextField(
                                    '车牌号', _licensePlateController, themeData,
                                    required: true,
                                    prefix: '黑A',
                                    maxLength: 17),
                                _buildTextField(
                                    '车辆类型', _vehicleTypeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField(
                                    '车主姓名', _ownerNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '身份证号码', _idCardNumberController, themeData,
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 18),
                                _buildTextField(
                                    '联系电话', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 20),
                                _buildTextField(
                                    '发动机号', _engineNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '车架号', _frameNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '车身颜色', _vehicleColorController, themeData,
                                    maxLength: 50),
                                _buildTextField('首次录入车牌号的日期',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    '当前状态', _currentStatusController, themeData,
                                    maxLength: 50),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitVehicle,
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

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
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
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    setState(() {
      _licensePlateController.text =
          widget.vehicle.licensePlate?.replaceFirst('黑A', '') ?? '';
      _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
      _ownerNameController.text = widget.vehicle.ownerName ?? '';
      _idCardNumberController.text = widget.vehicle.idCardNumber ?? '';
      _contactNumberController.text = widget.vehicle.contactNumber ?? '';
      _engineNumberController.text = widget.vehicle.engineNumber ?? '';
      _frameNumberController.text = widget.vehicle.frameNumber ?? '';
      _vehicleColorController.text = widget.vehicle.vehicleColor ?? '';
      _firstRegistrationDateController.text =
          formatDate(widget.vehicle.firstRegistrationDate);
      _currentStatusController.text = widget.vehicle.currentStatus ?? '';
    });
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final newLicensePlate = '黑A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(newLicensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (newLicensePlate != widget.vehicle.licensePlate &&
        await vehicleApi.apiVehiclesExistsGet(licensePlate: newLicensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }
    final idCardNumber = _idCardNumberController.text.trim();
    if (!isValidIdCardNumber(idCardNumber)) {
      _showSnackBar('身份证号码格式无效，请输入有效的15或18位身份证号码', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': widget.vehicle.vehicleId,
        'licensePlate': newLicensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': idCardNumber,
        'contactNumber': _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        'engineNumber': _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        'frameNumber': _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        'firstRegistrationDate': _firstRegistrationDateController.text.isEmpty
            ? null
            : '${_firstRegistrationDateController.text.trim()}T00:00:00.000',
        'currentStatus': _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      };
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/vehicles/${widget.vehicle.vehicleId}?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(vehiclePayload),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update vehicle: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('更新车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新车辆失败: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
      initialDate: widget.vehicle.firstRegistrationDate ?? DateTime.now(),
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
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix,
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
          helperText: label == '车牌号'
              ? '请输入车牌号后缀，例如：12345'
              : label == '身份证号码'
                  ? '请输入15或18位身份证号码'
                  : label == '联系电话'
                      ? '请输入11位手机号码'
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
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly && label == '首次录入车牌号的日期'
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
          hintText: readOnly && label == '身份证号码' ? '请在用户信息管理中修改身份证号码' : null,
          hintStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '车牌号' && trimmedValue.isNotEmpty) {
                final fullPlate = '黑A$trimmedValue';
                if (fullPlate.length > 20) return '车牌号不能超过20个字符';
                if (!isValidLicensePlate(fullPlate)) {
                  return '车牌号格式无效（例如：黑A12345）';
                }
              }
              if (label == '车辆类型' && trimmedValue.length > 50) {
                return '车辆类型不能超过50个字符';
              }
              if (label == '车主姓名' && trimmedValue.length > 100) {
                return '车主姓名不能超过100个字符';
              }
              if (label == '身份证号码') {
                if (trimmedValue.isEmpty) return '身份证号码不能为空';
                if (trimmedValue.length > 18) {
                  return '身份证号码不能超过18个字符';
                }
                if (!isValidIdCardNumber(trimmedValue)) {
                  return '身份证号码格式无效';
                }
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) {
                  return '请输入有效的11位手机号码';
                }
              }
              if (label == '发动机号' && trimmedValue.length > 50) {
                return '发动机号不能超过50个字符';
              }
              if (label == '车架号' && trimmedValue.length > 50) {
                return '车架号不能超过50个字符';
              }
              if (label == '车身颜色' && trimmedValue.length > 50) {
                return '车身颜色不能超过50个字符';
              }
              if (label == '首次录入车牌号的日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '首次录入日期不能晚于当前日期';
                }
              }
              if (label == '当前状态' && trimmedValue.length > 50) {
                return '当前状态不能超过50个字符';
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
          title: Text('编辑车辆信息',
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
                                    '车牌号', _licensePlateController, themeData,
                                    required: true,
                                    prefix: '黑A',
                                    maxLength: 17),
                                _buildTextField(
                                    '车辆类型', _vehicleTypeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField(
                                    '车主姓名', _ownerNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    '身份证号码', _idCardNumberController, themeData,
                                    required: true,
                                    readOnly: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 18),
                                _buildTextField(
                                    '联系电话', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 20),
                                _buildTextField(
                                    '发动机号', _engineNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '车架号', _frameNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    '车身颜色', _vehicleColorController, themeData,
                                    maxLength: 50),
                                _buildTextField('首次录入车牌号的日期',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    '当前状态', _currentStatusController, themeData,
                                    maxLength: 50),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitVehicle,
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

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';
  String? _currentDriverName;
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
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');
      await vehicleApi.initializeWithJwt();
      final user = await _fetchUserManagement();
      final driverInfo = user?.userId != null
          ? await _fetchDriverInformation(user!.userId)
          : null;
      _currentDriverName = driverInfo?.name ?? username;
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return null;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        return UserManagement.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      setState(() => _errorMessage = '获取用户信息失败: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return null;
      }
      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      return await driverApi.apiDriversDriverIdGet(driverId: userId);
    } catch (e) {
      setState(() => _errorMessage = '获取司机信息失败: $e');
      return null;
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
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
            (JwtDecoder.decode(jwtToken)['roles'] is String
                ? [JwtDecoder.decode(jwtToken)['roles']]
                : []);
        debugPrint('User roles from /api/users/me: $roles');
        debugPrint('Full userData: $userData');
        setState(
            () => _isEditable = roles.contains('ADMIN') || // Changed to ADMIN
                (_currentDriverName == widget.vehicle.ownerName));
      } else {
        debugPrint(
            'Role check failed: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking role: $e');
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('确认删除',
              style: themeData.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          content: Text('您确定要$action此车辆吗？此操作不可撤销。',
              style: themeData.textTheme.bodyMedium
                  ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消',
                  style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
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
                if (_errorMessage.contains('登录'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
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

      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('车辆详情',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isEditable
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditVehiclePage(vehicle: widget.vehicle)))
                          .then((value) {
                        if (value == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    },
                    tooltip: '编辑车辆信息',
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: () => _showDeleteConfirmationDialog('删除',
                        () => _deleteVehicle(widget.vehicle.vehicleId ?? 0)),
                    tooltip: '删除车辆',
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
                          _buildDetailRow('车辆类型',
                              widget.vehicle.vehicleType ?? '未知类型', themeData),
                          _buildDetailRow('车牌号',
                              widget.vehicle.licensePlate ?? '未知车牌', themeData),
                          _buildDetailRow('车主姓名',
                              widget.vehicle.ownerName ?? '未知车主', themeData),
                          _buildDetailRow('车辆状态',
                              widget.vehicle.currentStatus ?? '无', themeData),
                          _buildDetailRow('身份证号码',
                              widget.vehicle.idCardNumber ?? '无', themeData),
                          _buildDetailRow('联系电话',
                              widget.vehicle.contactNumber ?? '无', themeData),
                          _buildDetailRow('发动机号',
                              widget.vehicle.engineNumber ?? '无', themeData),
                          _buildDetailRow('车架号',
                              widget.vehicle.frameNumber ?? '无', themeData),
                          _buildDetailRow('车身颜色',
                              widget.vehicle.vehicleColor ?? '无', themeData),
                          _buildDetailRow(
                              '首次录入车牌号的日期',
                              formatDate(widget.vehicle.firstRegistrationDate),
                              themeData),
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
