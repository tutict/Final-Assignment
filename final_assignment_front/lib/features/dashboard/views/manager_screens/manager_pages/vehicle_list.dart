import 'dart:convert';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
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
  bool _isAdmin = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchType = 'licensePlate';

  final DashboardController controller = Get.find<DashboardController>();

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
        setState(() => _isAdmin = roles.contains('ROLE_ADMIN'));
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
      List<String> suggestions = [];
      if (_searchType == 'licensePlate') {
        suggestions = await vehicleApi.apiVehiclesAutocompleteLicensePlateGloballyMeGet(
          prefix: prefix,
          maxSuggestions: 5,
        );
      } else {
        suggestions = await vehicleApi.apiVehiclesAutocompleteVehicleTypeGloballyMeGet(
          prefix: prefix,
          maxSuggestions: 5,
        );
      }
      return suggestions;
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

    final searchQuery = query?.trim() ?? '';
    try {
      List<VehicleInformation> vehicles = [];
      if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
        vehicles = await vehicleApi.apiVehiclesGet(
          page: _currentPage,
          size: _pageSize,
        );
      } else {
        String searchQueryString = '';
        if (searchQuery.isNotEmpty) {
          searchQueryString = '$_searchType:$searchQuery';
        }
        if (_startDate != null && _endDate != null) {
          final startDateStr = formatDate(_startDate);
          final endDateStr = formatDate(_endDate);
          searchQueryString +=
              '${searchQueryString.isNotEmpty ? ' ' : ''}firstRegistrationDate:[$startDateStr TO $endDateStr]';
        }

        if (searchQueryString.isNotEmpty) {
          vehicles = await vehicleApi.apiVehiclesSearchGet(
            query: searchQueryString,
            page: _currentPage,
            size: _pageSize,
          );
        } else {
          vehicles = await vehicleApi.apiVehiclesGet(
            page: _currentPage,
            size: _pageSize,
          );
          vehicles = vehicles.where((vehicle) {
            if (vehicle.firstRegistrationDate == null) return false;
            return vehicle.firstRegistrationDate!.isAfter(_startDate!) &&
                vehicle.firstRegistrationDate!.isBefore(_endDate!);
          }).toList();
        }
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
        if (e.toString().contains('404')) {
          _vehicleList.clear();
          _errorMessage =
              '未找到符合条件的车辆，可能${_searchType == 'vehicleType' ? '车辆类型' : '车牌号'} "$searchQuery" 不存在';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取车辆信息失败: $e';
        }
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
      _searchType = 'licensePlate';
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
        final themeData = controller.currentBodyTheme.value;
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
                                  _fetchVehicles(reset: true);
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
                      onChanged: (value) => setState(() {}),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option,
                                    style: TextStyle(
                                        color:
                                            themeData.colorScheme.onSurface)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
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
                    _fetchVehicles(reset: true);
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
                          data: controller.currentBodyTheme.value,
                          child: child!);
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('车辆管理',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshVehicles,
                tooltip: '刷新车辆列表'),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createVehicle,
                tooltip: '添加新车辆信息'),
            IconButton(
              icon: Icon(themeData.brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
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
                                              color:
                                                  themeData.colorScheme.error,
                                              fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_errorMessage.contains('未授权'))
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
                                itemCount:
                                    _vehicleList.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _vehicleList.length &&
                                      _hasMore) {
                                    return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  }
                                  final vehicle = _vehicleList[index];
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
                                        '车牌号: ${vehicle.licensePlate ?? '未知车牌'}',
                                        style: themeData.textTheme.titleMedium
                                            ?.copyWith(
                                                color: themeData
                                                    .colorScheme.onSurface,
                                                fontWeight: FontWeight.w600),
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
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '车主: ${vehicle.ownerName ?? '未知车主'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '状态: ${vehicle.currentStatus ?? '无'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
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
                                                Icon(Icons.arrow_forward_ios,
                                                    color: themeData.colorScheme
                                                        .onSurfaceVariant,
                                                    size: 18),
                                              ],
                                            )
                                          : Icon(Icons.arrow_forward_ios,
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                              size: 18),
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');

      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await _preFillForm(username);
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preFillForm(String username) async {
    final user = await _fetchUserManagement();
    final driverInfo = user?.userId != null
        ? await driverApi.apiDriversDriverIdGet(driverId: user!.userId)
        : null;

    if (driverInfo == null || driverInfo.name == null) {
      throw Exception(
          '无法获取驾驶员信息或姓名 (Driver ID: ${user?.userId}, Username: $username)');
    }

    setState(() {
      _ownerNameController.text = driverInfo.name!;
      _idCardNumberController.text = driverInfo.idCardNumber ?? '';
      _contactNumberController.text =
          driverInfo.contactNumber ?? user?.contactNumber ?? '';
    });
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
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
      debugPrint('Error fetching UserManagement: $e');
      return null;
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
    if (await vehicleApi.apiVehiclesExistsGet(licensePlate: licensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': null,
        'licensePlate': licensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
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
            ? null
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
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
      String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
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
                                    required: true, prefix: '黑A'),
                                _buildTextField(
                                    '车辆类型', _vehicleTypeController, themeData,
                                    required: true),
                                _buildTextField(
                                    '车主姓名', _ownerNameController, themeData,
                                    required: true, readOnly: true),
                                _buildTextField(
                                    '身份证号码', _idCardNumberController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '联系电话', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone),
                                _buildTextField(
                                    '发动机号', _engineNumberController, themeData),
                                _buildTextField(
                                    '车架号', _frameNumberController, themeData),
                                _buildTextField(
                                    '车身颜色', _vehicleColorController, themeData),
                                _buildTextField('首次注册日期',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField('当前状态',
                                    _currentStatusController, themeData),
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeFields() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) throw Exception('未找到 JWT');
    final decodedToken = JwtDecoder.decode(jwtToken);
    final username = decodedToken['sub'] ?? '';
    if (username.isEmpty) throw Exception('JWT 中未找到用户名');

    final user = await _fetchUserManagement();
    final driverInfo = user?.userId != null
        ? await driverApi.apiDriversDriverIdGet(driverId: user!.userId)
        : null;
    if (driverInfo == null || driverInfo.name == null) {
      throw Exception('无法获取驾驶员信息或姓名');
    }

    setState(() {
      _licensePlateController.text =
          widget.vehicle.licensePlate?.replaceFirst('黑A', '') ?? '';
      _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
      _ownerNameController.text = driverInfo.name!; // Locked to driver name
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

  Future<UserManagement?> _fetchUserManagement() async {
    try {
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
      debugPrint('Failed to fetch UserManagement: $e');
      return null;
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

    final newLicensePlate = '黑A${_licensePlateController.text.trim()}';
    if (newLicensePlate != widget.vehicle.licensePlate &&
        await vehicleApi.apiVehiclesExistsGet(licensePlate: newLicensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': widget.vehicle.vehicleId,
        'licensePlate': newLicensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
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
            ? null
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.vehicle.firstRegistrationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
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
      String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
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
                                    required: true, prefix: '黑A'),
                                _buildTextField(
                                    '车辆类型', _vehicleTypeController, themeData,
                                    required: true),
                                _buildTextField(
                                    '车主姓名', _ownerNameController, themeData,
                                    required: true, readOnly: true),
                                _buildTextField(
                                    '身份证号码', _idCardNumberController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '联系电话', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone),
                                _buildTextField(
                                    '发动机号', _engineNumberController, themeData),
                                _buildTextField(
                                    '车架号', _frameNumberController, themeData),
                                _buildTextField(
                                    '车身颜色', _vehicleColorController, themeData),
                                _buildTextField('首次注册日期',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField('当前状态',
                                    _currentStatusController, themeData),
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
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
      debugPrint('Failed to fetch UserManagement: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      return await driverApi.apiDriversDriverIdGet(driverId: userId);
    } catch (e) {
      debugPrint('Failed to fetch DriverInformation: $e');
      return null;
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
        setState(() => _isEditable = roles.contains('ROLE_ADMIN') ||
            (_currentDriverName == widget.vehicle.ownerName));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    setState(() => _isLoading = true);
    try {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
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
                              '首次注册日期',
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
