import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:get/get.dart';
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
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final List<VehicleInformation> _vehicleList = [];
  List<VehicleInformation> _filteredVehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  String? _currentDriverIdCardNumber;
  bool _hasMore = true;
  String _searchType = 'licensePlate';

  final UserDashboardController controller =
      Get.find<UserDashboardController>();

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
      await userApi.initializeWithJwt();

      final user = await _fetchUserManagement();
      final userId = user?.userId;
      final driverInfo = userId != null
          ? await driverApi.apiDriversDriverIdGet(driverId: userId)
          : null;
      _currentDriverName = driverInfo?.name ?? username;
      _currentDriverIdCardNumber = driverInfo?.idCardNumber;
      debugPrint(
          'Current driver name: $_currentDriverName, idCardNumber: $_currentDriverIdCardNumber');

      if (_currentDriverIdCardNumber == null ||
          _currentDriverIdCardNumber!.isEmpty) {
        throw Exception('未找到身份证号码，请确保驾驶员信息已完善');
      }

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
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        debugPrint('Username not found in local storage');
        return null;
      }
      await userApi.initializeWithJwt();
      return await userApi.apiUsersSearchUsernameGet(
          username: storedUsername);
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
    if (_currentDriverIdCardNumber == null) {
      setState(() {
        _errorMessage = '缺少身份证号码，无法获取车辆信息';
        _isLoading = false;
      });
      return;
    }

    if (reset) {
      _hasMore = true;
      _vehicleList.clear();
      _filteredVehicleList.clear();
    }
    if (!_hasMore && query == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    debugPrint(
        'Fetching vehicles with query: $searchQuery, searchType: $_searchType');

    try {
      final vehicles = await vehicleApi.apiVehiclesSearchOwnerGet(
        idCard: _currentDriverIdCardNumber!,
      );

      debugPrint(
          'Vehicles fetched: ${vehicles.map((v) => v.toJson()).toList()}');
      setState(() {
        _vehicleList
          ..clear()
          ..addAll(vehicles);
        _hasMore = false;
        _applyFilters(searchQuery);
        if (_filteredVehicleList.isEmpty) {
          _errorMessage = searchQuery.isNotEmpty ? '未找到符合条件的车辆' : '您当前没有车辆记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('400')) {
          _errorMessage = '身份证号码或查询无效，请检查后重试';
        } else if (e.toString().contains('404')) {
          _vehicleList.clear();
          _filteredVehicleList.clear();
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

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredVehicleList.clear();
        _filteredVehicleList.addAll(_vehicleList);
      } else {
        _filteredVehicleList = _vehicleList.where((vehicle) {
          final licensePlate = (vehicle.licensePlate ?? '').toLowerCase();
          final vehicleType = (vehicle.vehicleType ?? '').toLowerCase();
          if (_searchType == 'licensePlate') {
            return licensePlate.contains(searchQuery);
          } else {
            return vehicleType.contains(searchQuery);
          }
        }).toList();
      }
      if (_filteredVehicleList.isEmpty && _vehicleList.isNotEmpty) {
        _errorMessage = '未找到符合条件的车辆';
      } else {
        _errorMessage = _filteredVehicleList.isEmpty && _vehicleList.isEmpty
            ? '您当前没有车辆记录'
            : '';
      }
      debugPrint('Filtered vehicles: ${_filteredVehicleList.length}');
    });
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    if (_currentDriverIdCardNumber == null) {
      debugPrint('Cannot fetch suggestions: idCardNumber is null');
      return [];
    }
    try {
      if (_searchType == 'licensePlate') {
        debugPrint(
            'Fetching license plate suggestions for idCardNumber: $_currentDriverIdCardNumber, prefix: $prefix');
        final suggestions = await vehicleApi.apiVehiclesAutocompletePlatesGet(
          prefix: prefix,
          idCard: _currentDriverIdCardNumber!,
          size: 5,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      } else {
        debugPrint(
            'Fetching vehicle type suggestions for idCardNumber: $_currentDriverIdCardNumber, prefix: $prefix');
        final suggestions = await vehicleApi.apiVehiclesAutocompleteTypesGet(
          prefix: prefix,
          idCard: _currentDriverIdCardNumber!,
          size: 5,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    await _fetchUserVehicles(query: _searchController.text);
  }

  Future<void> _refreshVehicles() async {
    _searchController.clear();
    await _fetchUserVehicles(reset: true);
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
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
                _searchController.text = controller.text;
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
                  onChanged: (value) => _applyFilters(value),
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
                    child: _isLoading && _vehicleList.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    themeData.colorScheme.primary)))
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
                                              foregroundColor: themeData
                                                  .colorScheme.onPrimary),
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
                                        padding: EdgeInsets.all(8.0));
                                  }
                                  final vehicle = _filteredVehicleList[index];
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color:
                                                themeData.colorScheme.primary,
                                            onPressed: () =>
                                                _goToDetailPage(vehicle),
                                            tooltip: '编辑',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: themeData
                                                    .colorScheme.error),
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
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
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
      await userApi.initializeWithJwt();
      await _preFillForm(username);
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preFillForm(String username) async {
    final user = await _fetchUserManagement();
    final userId = user?.userId;
    final driverInfo = userId != null
        ? await driverApi.apiDriversDriverIdGet(driverId: userId)
        : null;

    debugPrint('Fetched UserManagement: ${user?.toJson()}');
    debugPrint('Fetched DriverInformation: ${driverInfo?.toString()}');

    if (driverInfo == null || driverInfo.name == null) {
      throw Exception(
          '无法获取驾驶员信息或姓名 (Driver ID: ${user?.userId}, Username: $username)');
    }

    setState(() {
      _ownerNameController.text = driverInfo.name!;
      _idCardNumberController.text = driverInfo.idCardNumber ?? '';
      _contactNumberController.text =
          driverInfo.contactNumber ?? user?.contactNumber ?? '';
      debugPrint('Set ownerNameController.text to: ${driverInfo.name}');
    });
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        debugPrint('Username missing when fetching user info');
        return null;
      }
      await userApi.initializeWithJwt();
      return await userApi.apiUsersSearchUsernameGet(
          username: storedUsername);
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
    if (!isValidLicensePlate(licensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }

    if (await vehicleApi.apiVehiclesExistsLicensePlateGet(
        licensePlate: licensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }

    final idCardNumber = _idCardNumberController.text.trim();
    if (idCardNumber.isEmpty) {
      _showSnackBar('请到个人-用户信息管理处填写身份证号码', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleInformation(
        vehicleId: null,
        licensePlate: licensePlate,
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerIdCard: idCardNumber,
        ownerContact: _contactNumberController.text.trim().isEmpty
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
            : DateTime.parse(
                '${_firstRegistrationDateController.text.trim()}T00:00:00.000'),
        status: _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesPost(
        vehicle: vehicle,
        idempotencyKey: idempotencyKey,
      );

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
          suffixIcon: readOnly && label == '首次注册日期'
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
                if (trimmedValue.length > 18) return '身份证号码不能超过18个字符';
                if (!isValidIdCardNumber(trimmedValue)) return '身份证号码格式无效';
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) return '请输入有效的11位手机号码';
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
              if (label == '首次注册日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) return '首次注册日期不能晚于当前日期';
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
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
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
                                Text('您当前没有车辆记录，请添加新车辆',
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold)),
                              if (widget.onVehicleAdded != null)
                                const SizedBox(height: 16),
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true, prefix: '黑A', maxLength: 17),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true, maxLength: 50),
                              _buildTextField(
                                  '车主姓名', _ownerNameController, themeData,
                                  required: true,
                                  readOnly: true,
                                  maxLength: 100),
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
                              _buildTextField('首次注册日期',
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
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
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
      await userApi.initializeWithJwt();
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
    final userId = user?.userId;
    final driverInfo = userId != null
        ? await driverApi.apiDriversDriverIdGet(driverId: userId)
        : null;
    if (driverInfo == null || driverInfo.name == null) {
      throw Exception('无法获取驾驶员信息或姓名');
    }

    setState(() {
      _licensePlateController.text =
          widget.vehicle.licensePlate?.replaceFirst('黑A', '') ?? '';
      _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
      _ownerNameController.text = driverInfo.name!;
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
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        debugPrint('Username missing when fetching user info');
        return null;
      }
      await userApi.initializeWithJwt();
      return await userApi.apiUsersSearchUsernameGet(
          username: storedUsername);
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
    if (!isValidLicensePlate(newLicensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }

    if (newLicensePlate != widget.vehicle.licensePlate &&
        await vehicleApi.apiVehiclesExistsLicensePlateGet(
            licensePlate: newLicensePlate)) {
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
        ownerIdCard: _idCardNumberController.text.trim(),
        ownerContact: _contactNumberController.text.trim().isEmpty
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
            : DateTime.parse(
                '${_firstRegistrationDateController.text.trim()}T00:00:00.000'),
        status: _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicle: vehicle,
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
          suffixIcon: readOnly && label == '首次注册日期'
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
                if (trimmedValue.length > 18) return '身份证号码不能超过18个字符';
                if (!isValidIdCardNumber(trimmedValue)) return '身份证号码格式无效';
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) return '请输入有效的11位手机号码';
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
              if (label == '首次注册日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) return '首次注册日期不能晚于当前日期';
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
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
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
                                  required: true, prefix: '黑A', maxLength: 17),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true, maxLength: 50),
                              _buildTextField(
                                  '车主姓名', _ownerNameController, themeData,
                                  required: true,
                                  readOnly: true,
                                  maxLength: 100),
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
                              _buildTextField('首次注册日期',
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
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';
  String? _currentDriverIdCardNumber;

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
      await userApi.initializeWithJwt();
      final user = await _fetchUserManagement();
      final userId = user?.userId;
      final driverInfo =
          userId != null ? await _fetchDriverInformation(userId) : null;
      _currentDriverIdCardNumber = driverInfo?.idCardNumber;
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
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        debugPrint('Username missing when fetching user info');
        return null;
      }
      await userApi.initializeWithJwt();
      return await userApi.apiUsersSearchUsernameGet(
          username: storedUsername);
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
      final roles = decodedToken['roles']?.toString().split(',') ?? [];
      setState(() {
        _isEditable = roles.contains('ROLE_ADMIN') ||
            (_currentDriverIdCardNumber != null &&
                _currentDriverIdCardNumber == widget.vehicle.idCardNumber);
      });
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
        final themeData =
            controller?.currentBodyTheme.value ?? ThemeData.light();
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
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
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
