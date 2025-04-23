import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
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

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  String? _currentDriverIdCardNumber;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchType = 'licensePlate'; // Default search type

  final UserDashboardController controller = Get.find<UserDashboardController>();

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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');
      debugPrint('Current username from JWT: $username');

      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();

      final user = await _fetchUserManagement();
      final driverInfo = user?.userId != null
          ? await driverApi.apiDriversDriverIdGet(driverId: user!.userId)
          : null;
      _currentDriverName = driverInfo?.name ?? username;
      _currentDriverIdCardNumber = driverInfo?.idCardNumber;
      debugPrint('Current driver name: $_currentDriverName');

      await _fetchUserVehicles(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserVehicles({bool reset = false, String? query}) async {
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

    // Declare searchQuery outside the try block
    final searchQuery = query?.trim() ?? '';
    debugPrint(
        'Fetching vehicles with query: $searchQuery, page: $_currentPage, searchType: $_searchType');

    try {
      List<VehicleInformation> vehicles = [];
      if (searchQuery.isEmpty) {
        debugPrint(
            'Fetching all vehicles for owner: $_currentDriverIdCardNumber, page: $_currentPage');
        vehicles = await vehicleApi.apiVehiclesOwnerIdCardNumberGet(
          idCardNumber: _currentDriverIdCardNumber,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_searchType == 'licensePlate' && searchQuery.length >= 3) {
        // Use specific lookup for license plate if query is detailed enough
        debugPrint('Fetching vehicle by license plate: $searchQuery');
        final vehicle = await vehicleApi.apiVehiclesLicensePlateGet(
            licensePlate: searchQuery);
        vehicles = vehicle != null && vehicle.ownerName == _currentDriverName
            ? [vehicle]
            : [];
      } else if (_searchType == 'vehicleType' && searchQuery.length >= 2) {
        // Use specific lookup for vehicle type if query is detailed enough
        debugPrint('Fetching vehicle by vehicle type: $searchQuery');
        vehicles =
            await vehicleApi.apiVehiclesTypeGet(vehicleType: searchQuery);
        vehicles = vehicles
            .where((vehicle) => vehicle.ownerName == _currentDriverName)
            .toList();
      } else {
        debugPrint('Searching vehicles with query: $searchQuery');
        vehicles = await vehicleApi.apiVehiclesSearchGet(
          query: '$_searchType:$searchQuery ownerName:$_currentDriverName',
          page: _currentPage,
          size: _pageSize,
        );
      }

      debugPrint(
          'Vehicles fetched: ${vehicles.map((v) => v.toJson()).toList()}');
      setState(() {
        _vehicleList.addAll(vehicles);
        if (vehicles.length < _pageSize) _hasMore = false;
        if (_vehicleList.isEmpty && _currentPage == 1) {
          _errorMessage = searchQuery.isNotEmpty ? '未找到符合条件的车辆' : '您当前没有车辆记录';
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

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (_searchType == 'licensePlate') {
        debugPrint(
            'Fetching license plate suggestions for owner: $_currentDriverName, prefix: $prefix');
        return await vehicleApi.apiVehiclesAutocompleteLicensePlateMeGet(
          prefix: prefix,
          maxSuggestions: 5,
          ownerName: _currentDriverName,
        );
      } else {
        debugPrint(
            'Fetching vehicle type suggestions for owner: $_currentDriverName, prefix: $prefix');
        return await vehicleApi.apiVehiclesAutocompleteVehicleTypeMeGet(
          prefix: prefix,
          maxSuggestions: 5,
          ownerName: _currentDriverName,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchUserVehicles(query: _searchController.text);
  }

  Future<void> _refreshVehicles() async {
    _searchController.clear();
    await _fetchUserVehicles(reset: true);
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    await _fetchUserVehicles(reset: true, query: query);
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) _fetchUserVehicles(reset: true);
    });
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchUserVehicles(reset: true);
    });
  }

  Future<void> _deleteVehicle(int vehicleId, String licensePlate) async {
    _showDeleteConfirmationDialog('删除', () async {
      setState(() => _isLoading = true);
      try {
        await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
        _showSnackBar('删除车辆成功！');
        _fetchUserVehicles(reset: true);
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    });
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

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData =
            controller.currentBodyTheme.value;
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

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
                    hintText:
                        _searchType == 'licensePlate' ? '搜索车牌号' : '搜索车辆类型',
                    hintStyle: TextStyle(
                        color:
                            themeData.colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              controller.clear();
                              _searchController.clear();
                              _fetchUserVehicles(reset: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
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
                  onSubmitted: (value) => _searchVehicles(),
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
                _fetchUserVehicles(reset: true);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller.currentBodyTheme.value;

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
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: themeData.colorScheme.primary,
                                          onPressed: () =>
                                              _goToDetailPage(vehicle),
                                          tooltip: '编辑',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color:
                                                  themeData.colorScheme.error),
                                          onPressed: () => _deleteVehicle(
                                              vehicle.vehicleId ?? 0,
                                              vehicle.licensePlate ?? ''),
                                          tooltip: '删除',
                                        ),
                                      ],
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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

    debugPrint('Fetched UserManagement: ${user?.toJson()}');
    debugPrint('Fetched DriverInformation: ${driverInfo?.toString()}');

    if (driverInfo == null || driverInfo.name == null) {
      throw Exception(
          '无法获取驾驶员信息或姓名 (Driver ID: ${user?.userId}, Username: $username)');
    }

    setState(() {
      _ownerNameController.text =
          driverInfo.name!; // Must be DriverInformation.name
      _idCardNumberController.text = driverInfo.idCardNumber ?? '';
      _contactNumberController.text =
          driverInfo.contactNumber ?? user?.contactNumber ?? '';
      debugPrint('Set ownerNameController.text to: ${driverInfo.name}');
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
      debugPrint(
          'Failed to fetch UserManagement: Status ${response.statusCode}');
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
      debugPrint('Submitting with ownerName: ${_ownerNameController.text}');

      // Manually construct the JSON payload to avoid serialization override
      final vehiclePayload = {
        'vehicleId': null,
        'licensePlate': licensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(), // Forcefully use 黄广龙
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
      debugPrint(
          'Manually constructed JSON payload: ${jsonEncode(vehiclePayload)}');

      // Use a raw HTTP POST to bypass the generated client’s serialization
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

      debugPrint(
          'Raw POST Response: ${response.statusCode} - ${response.body}');

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: controller?.currentBodyTheme.value.colorScheme.primary),
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
        readOnly: readOnly || label == '车主姓名',
        // Lock ownerName
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: widget.onVehicleAdded != null
          ? null
          : AppBar(
              title: Text(
                '添加新车辆',
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
                              if (widget.onVehicleAdded != null)
                                Text(
                                  '您当前没有车辆记录，请添加新车辆',
                                  style:
                                      themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData),
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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
      _ownerNameController.text =
          driverInfo.name!; // Lock to DriverInformation.name
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
      final vehicle = VehicleInformation(
        vehicleId: widget.vehicle.vehicleId,
        licensePlate: newLicensePlate,
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        // Locked to DriverInformation.name
        idCardNumber: _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        firstRegistrationDate: _firstRegistrationDateController.text.isEmpty
            ? null
            : DateTime.parse(_firstRegistrationDateController.text.trim()),
        currentStatus: _currentStatusController.text.trim().isEmpty
            ? null
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicleInformation: vehicle,
        idempotencyKey: idempotencyKey,
      );

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: controller?.currentBodyTheme.value.colorScheme.primary),
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
        readOnly: readOnly || label == '车主姓名',
        // Lock ownerName
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '编辑车辆信息',
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
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData),
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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
      final decodedToken = JwtDecoder.decode(jwtToken);
      final currentUsername = decodedToken['sub'] ?? '';
      if (currentUsername.isEmpty) throw Exception('JWT 中未找到用户名');

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
                color: themeData.colorScheme.onSurface,
              )),
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

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
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
              if (_errorMessage.contains('登录'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.colorScheme.primary,
                      foregroundColor: themeData.colorScheme.onPrimary,
                    ),
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
        title: Text(
          '车辆详情',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
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
                              EditVehiclePage(vehicle: widget.vehicle)),
                    ).then((value) {
                      if (value == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  tooltip: '编辑车辆信息',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: themeData.colorScheme.error),
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
  }
}
