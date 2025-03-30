import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/process_pages/vehicle_management.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return '无';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isAdmin = false; // 判断是否为管理员
  DateTime? _startDate;
  DateTime? _endDate;

  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await vehicleApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      _currentDriverName = decodedToken['sub'] ?? '';
      if (_currentDriverName!.isEmpty) throw Exception('JWT 中未找到用户名');
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      debugPrint('Fetching vehicle type suggestions for prefix: $prefix');
      return await vehicleApi.apiVehiclesAutocompleteLicensePlateMeGet(
        prefix: prefix,
        maxSuggestions: 5,
      );
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _fetchVehicles({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _vehicleList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final searchQuery = query?.trim() ?? '';
      debugPrint(
          'Fetching vehicles with query: $searchQuery, page: $_currentPage, startDate: $_startDate, endDate: $_endDate');

      List<VehicleInformation> vehicles = [];
      if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
        debugPrint('Fetching all vehicles');
        vehicles = await vehicleApi.apiVehiclesGet(
          page: _currentPage,
          size: _pageSize,
        );
      } else if (searchQuery.isNotEmpty &&
          _startDate != null &&
          _endDate != null) {
        debugPrint('Filtering by vehicle type and date range');
        vehicles = await vehicleApi.apiVehiclesTypeGet(
          vehicleType: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
        vehicles = vehicles
            .where((vehicle) =>
                vehicle.firstRegistrationDate != null &&
                vehicle.firstRegistrationDate!.isAfter(_startDate!) &&
                vehicle.firstRegistrationDate!.isBefore(_endDate!))
            .toList();
      } else if (searchQuery.isNotEmpty) {
        debugPrint('Searching vehicles by vehicle type: $searchQuery');
        vehicles = await vehicleApi.apiVehiclesTypeGet(
          vehicleType: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_startDate != null && _endDate != null) {
        debugPrint('Filtering by date range');
        vehicles = await vehicleApi.apiVehiclesGet(
          page: _currentPage,
          size: _pageSize,
        );
        vehicles = vehicles
            .where((vehicle) =>
                vehicle.firstRegistrationDate != null &&
                vehicle.firstRegistrationDate!.isAfter(_startDate!) &&
                vehicle.firstRegistrationDate!.isBefore(_endDate!))
            .toList();
      }

      setState(() {
        _vehicleList.addAll(vehicles);
        if (vehicles.length < _pageSize) _hasMore = false;
        if (_vehicleList.isEmpty && _currentPage == 1) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startDate != null && _endDate != null)
                  ? '未找到符合条件的车辆'
                  : '当前没有车辆记录';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取车辆信息失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchVehicles(query: _searchController.text);
  }

  Future<void> _refreshVehicles() async {
    _searchController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    await _fetchVehicles(reset: true);
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    await _fetchVehicles(reset: true, query: query);
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  void _editVehicle(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVehiclePage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData =
            controller?.currentBodyTheme.value ?? ThemeData.light();
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: Text(
            '您确定要$action此车辆吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
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
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return await _fetchAutocompleteSuggestions(
                        textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _searchVehicles();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    _searchController.text =
                        controller.text; // Sync with outer controller
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: '搜索车辆类型',
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
                                  _refreshVehicles();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      onSubmitted: (value) => _searchVehicles(),
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
                  _startDate != null && _endDate != null
                      ? '首次注册日期范围: ${formatDate(_startDate)} 至 ${formatDate(_endDate)}'
                      : '选择首次注册日期范围',
                  style: TextStyle(
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
                        data: themeData,
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    setState(() {
                      _startDate = range.start;
                      _endDate = range.end;
                    });
                    _searchVehicles();
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
                    _searchVehicles();
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
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            )),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVehicles,
            tooltip: '刷新车辆列表',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createVehicle,
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVehicles,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                                  themeData.colorScheme.primary)))
                      : _errorMessage.isNotEmpty && _vehicleList.isEmpty
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
                                  if (_errorMessage.contains('未授权'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
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
                              itemCount:
                                  _vehicleList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _vehicleList.length && _hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final vehicle = _vehicleList[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 3,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    title: Text(
                                      '车牌号: ${vehicle.licensePlate ?? '未知车牌'}',
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.onSurface,
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
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '车主: ${vehicle.ownerName ?? '未知车主'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '状态: ${vehicle.currentStatus ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
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
                                                icon: Icon(Icons.delete,
                                                    size: 18,
                                                    color: themeData
                                                        .colorScheme.error),
                                                onPressed: () =>
                                                    _showDeleteConfirmationDialog(
                                                        '删除',
                                                        () => _deleteVehicle(
                                                            vehicle.vehicleId ??
                                                                0)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createVehicle,
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '添加新车辆',
        child: const Icon(Icons.add),
      ),
    );
  }
}
