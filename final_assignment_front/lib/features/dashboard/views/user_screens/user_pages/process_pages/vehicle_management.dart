import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 生成幂等性键的全局方法
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 格式化日期的全局方法
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
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();

  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentUsername;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

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
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('userName');
    final jwtToken = prefs.getString('jwtToken');
    if (_currentUsername == null || jwtToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录以查看您的车辆信息';
      });
      return;
    }
    await vehicleApi.initializeWithJwt();
    _fetchUserVehicles(reset: true);
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserVehicles({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _hasMore = true;
      _vehicleList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final vehicles = await vehicleApi.apiVehiclesGet(
        page: _currentPage,
        size: _pageSize,
        ownerName: _currentUsername,
      );
      setState(() {
        _vehicleList.addAll(vehicles);
        _isLoading = false;
        if (vehicles.length < _pageSize) _hasMore = false;
        if (_vehicleList.isEmpty && _currentPage == 0) {
          _errorMessage = '您当前没有车辆记录';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取车辆信息失败: $e';
      });
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchUserVehicles();
  }

  Future<void> _refreshVehicles() async {
    await _fetchUserVehicles(reset: true);
  }

  Future<void> _searchVehicles(String type, String query) async {
    if (query.isEmpty) {
      await _fetchUserVehicles(reset: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 0;
      _hasMore = true;
      _vehicleList.clear();
    });
    try {
      List<VehicleInformation> vehicles;
      switch (type) {
        case 'licensePlate':
          final vehicle = await vehicleApi
              .apiVehiclesLicensePlateLicensePlateGet(licensePlate: query);
          vehicles = (vehicle != null && vehicle.ownerName == _currentUsername)
              ? [vehicle]
              : [];
          _hasMore = false;
          break;
        case 'vehicleType':
          vehicles = await vehicleApi.apiVehiclesTypeVehicleTypeGet(
            vehicleType: query,
            page: _currentPage,
            size: _pageSize,
          );
          vehicles =
              vehicles.where((v) => v.ownerName == _currentUsername).toList();
          if (vehicles.length < _pageSize) _hasMore = false;
          break;
        case 'ownerName':
          if (query != _currentUsername) {
            setState(() {
              _isLoading = false;
              _hasMore = false;
              _errorMessage = '您只能查看自己的车辆信息';
            });
            return;
          }
          vehicles = await vehicleApi.apiVehiclesOwnerOwnerNameGet(
            ownerName: query,
            page: _currentPage,
            size: _pageSize,
          );
          if (vehicles.length < _pageSize) _hasMore = false;
          break;
        case 'currentStatus':
          vehicles = await vehicleApi.apiVehiclesStatusCurrentStatusGet(
            currentStatus: query,
            page: _currentPage,
            size: _pageSize,
          );
          vehicles =
              vehicles.where((v) => v.ownerName == _currentUsername).toList();
          if (vehicles.length < _pageSize) _hasMore = false;
          break;
        default:
          setState(() {
            _isLoading = false;
            _errorMessage = '无效的搜索类型';
          });
          return;
      }
      setState(() {
        _vehicleList = vehicles;
        _isLoading = false;
        if (_vehicleList.isEmpty) {
          _errorMessage = '未找到符合条件的车辆';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败：$e';
      });
    }
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) {
        _fetchUserVehicles(reset: true);
      }
    });
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) {
        _fetchUserVehicles(reset: true);
      }
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchUserVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    try {
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
      _fetchUserVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
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

  Widget _buildSearchField(String label, TextEditingController controller,
      String type, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(Icons.search,
                    color: themeData.colorScheme.primary, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withOpacity(0.3),
                      width: 1.0),
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
                    vertical: 10.0, horizontal: 12.0),
                labelStyle: themeData.textTheme.bodySmall
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
              style: themeData.textTheme.bodyMedium
                  ?.copyWith(color: themeData.colorScheme.onSurface),
              onSubmitted: (value) => _searchVehicles(type, value.trim()),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _searchVehicles(type, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            ),
            child: Text('搜索',
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: themeData.colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    if (!_isLoading && _errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, style: themeData.textTheme.bodyLarge),
              if (_errorMessage.contains('登录'))
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('前往登录'),
                ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆管理',
            style: themeData.textTheme.titleLarge
                ?.copyWith(color: themeData.colorScheme.onPrimary)),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshVehicles,
              tooltip: '刷新车辆列表'),
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createVehicle,
              tooltip: '添加新车辆信息'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVehicles,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildSearchField(
                  '按车牌号搜索', _licensePlateController, 'licensePlate', themeData),
              _buildSearchField(
                  '按车辆类型搜索', _vehicleTypeController, 'vehicleType', themeData),
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
                  child: _isLoading && _currentPage == 0
                      ? const Center(child: CircularProgressIndicator())
                      : _vehicleList.isEmpty
                          ? Center(
                              child: Text(
                                  _errorMessage.isNotEmpty
                                      ? _errorMessage
                                      : '暂无车辆信息',
                                  style: themeData.textTheme.bodyLarge))
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
                                final type = vehicle.vehicleType ?? '未知类型';
                                final plate = vehicle.licensePlate ?? '未知车牌';
                                final owner = vehicle.ownerName ?? '未知车主';
                                final status = vehicle.currentStatus ?? '无';
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: ListTile(
                                    title: Text('车牌号: $plate',
                                        style: themeData.textTheme.bodyLarge),
                                    subtitle: Text(
                                        '类型: $type\n车主: $owner\n状态: $status',
                                        style: themeData.textTheme.bodyMedium),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _goToDetailPage(vehicle);
                                        } else if (value == 'delete') {
                                          _deleteVehicle(
                                              vehicle.vehicleId ?? 0);
                                        } else if (value == 'deleteByPlate') {
                                          _deleteVehicleByLicensePlate(plate);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('查看/编辑')),
                                        const PopupMenuItem<String>(
                                            value: 'delete', child: Text('删除')),
                                      ],
                                      icon: Icon(Icons.more_vert,
                                          color:
                                              themeData.colorScheme.onSurface),
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

/// ==================== 添加车辆页面 ====================

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final ApiClient apiClient = ApiClient();
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
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final username = prefs.getString('userName');
    if (jwtToken != null) {
      apiClient.setJwtToken(jwtToken);
      vehicleApi.apiClient.setJwtToken(jwtToken);
      driverApi.apiClient.setJwtToken(jwtToken);
      _ownerNameController.text = username ?? '';
      await _preFillForm();
    }
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      final response = await apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        {},
        {},
        'application/json',
        ['bearerAuth'],
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserManagement.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch UserManagement: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      return await driverApi.apiDriversDriverIdGet(driverId: userId.toString());
    } catch (e) {
      debugPrint('Failed to fetch DriverInformation: $e');
      return null;
    }
  }

  Future<void> _preFillForm() async {
    final user = await _fetchUserManagement();
    final driverInfo = user != null && user.userId != null
        ? await _fetchDriverInformation(user.userId!)
        : null;

    setState(() {
      _ownerNameController.text =
          driverInfo?.name ?? user?.username ?? _ownerNameController.text;
      _idCardNumberController.text = driverInfo?.idCardNumber ?? '';
      _contactNumberController.text =
          driverInfo?.contactNumber ?? user?.contactNumber ?? '';
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

    setState(() => _isLoading = true);
    try {
      DateTime? firstRegistrationDate;
      if (_firstRegistrationDateController.text.isNotEmpty) {
        firstRegistrationDate =
            DateTime.parse(_firstRegistrationDateController.text.trim());
      }

      final vehicle = VehicleInformation(
        licensePlate: _licensePlateController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
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
        firstRegistrationDate: firstRegistrationDate,
        currentStatus: _currentStatusController.text.trim().isEmpty
            ? null
            : _currentStatusController.text.trim(),
      );

      vehicle.validateForCreation();

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesPost(
        vehicleInformation: vehicle,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建车辆成功！');
      if (mounted) Navigator.pop(context, true);
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
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary:
                    controller?.currentBodyTheme.value.colorScheme.primary ??
                        Colors.blue,
                onPrimary:
                    controller?.currentBodyTheme.value.colorScheme.onPrimary ??
                        Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _firstRegistrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    ThemeData themeData, {
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: themeData.textTheme.bodySmall
              ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.3),
                width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: themeData.textTheme.bodyMedium
            ?.copyWith(color: themeData.colorScheme.onSurface),
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
        title: Text('添加新车辆',
            style: themeData.textTheme.titleLarge
                ?.copyWith(color: themeData.colorScheme.onPrimary)),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        color: themeData.colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true),
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
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          elevation: 3,
                        ),
                        child: Text('提交',
                            style: themeData.textTheme.labelLarge?.copyWith(
                                color: themeData.colorScheme.onPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// ==================== 编辑车辆页面 ====================

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
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
    _initializeFields();
    vehicleApi.initializeWithJwt();
  }

  void _initializeFields() {
    _licensePlateController.text = widget.vehicle.licensePlate ?? '';
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

    setState(() => _isLoading = true);
    try {
      DateTime? firstRegistrationDate;
      if (_firstRegistrationDateController.text.isNotEmpty) {
        firstRegistrationDate =
            DateTime.parse(_firstRegistrationDateController.text.trim());
      }

      final vehicle = VehicleInformation(
        vehicleId: widget.vehicle.vehicleId,
        licensePlate: _licensePlateController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
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
        firstRegistrationDate: firstRegistrationDate,
        currentStatus: _currentStatusController.text.trim().isEmpty
            ? null
            : _currentStatusController.text.trim(),
      );

      vehicle.validateForCreation();

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
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary:
                    controller?.currentBodyTheme.value.colorScheme.primary ??
                        Colors.blue,
                onPrimary:
                    controller?.currentBodyTheme.value.colorScheme.onPrimary ??
                        Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _firstRegistrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    ThemeData themeData, {
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: themeData.textTheme.bodySmall
              ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.3),
                width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: themeData.textTheme.bodyMedium
            ?.copyWith(color: themeData.colorScheme.onSurface),
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
        title: Text('编辑车辆信息',
            style: themeData.textTheme.titleLarge
                ?.copyWith(color: themeData.colorScheme.onPrimary)),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        color: themeData.colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true),
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
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          elevation: 3,
                        ),
                        child: Text('保存',
                            style: themeData.textTheme.labelLarge?.copyWith(
                                color: themeData.colorScheme.onPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// ==================== 车辆详情页面 ====================

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
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      vehicleApi.apiClient.setJwtToken(jwtToken);
    }
    await _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final currentUsername = prefs.getString('userName');
      if (jwtToken == null || currentUsername == null) {
        throw Exception('未登录，请重新登录');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        // Safely handle roles, defaulting to an empty list if null
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        final username = userData['sub'] as String? ?? currentUsername;

        setState(() {
          _isEditable = roles.contains('ROLE_ADMIN') ||
              (username == widget.vehicle.ownerName);
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载权限失败: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
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
        duration: const Duration(seconds: 2),
      ),
    );
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

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData =
            controller?.currentBodyTheme.value ?? ThemeData.light();
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.titleMedium?.copyWith(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '您确定要$action此车辆吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium
                ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: themeData.colorScheme.onSurface),
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
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              child: Text(
                '删除',
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: themeData.colorScheme.onError),
              ),
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
                  style: themeData.textTheme.bodyLarge
                      ?.copyWith(color: themeData.colorScheme.error)),
              if (_errorMessage.contains('登录'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.colorScheme.primary,
                      foregroundColor: themeData.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                    ),
                    child: Text('前往登录',
                        style: themeData.textTheme.labelLarge
                            ?.copyWith(color: themeData.colorScheme.onPrimary)),
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
          style: themeData.textTheme.titleLarge
              ?.copyWith(color: themeData.colorScheme.onPrimary),
        ),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
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
                  color: themeData.colorScheme.onPrimary,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmationDialog('按ID删除',
                          () => _deleteVehicle(widget.vehicle.vehicleId ?? 0));
                    } else if (value == 'deleteByPlate') {
                      _showDeleteConfirmationDialog(
                          '按车牌删除',
                          () => _deleteVehicleByLicensePlate(
                              widget.vehicle.licensePlate ?? ''));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child:
                          Text('按ID删除', style: themeData.textTheme.bodyMedium),
                    ),
                    PopupMenuItem<String>(
                      value: 'deleteByPlate',
                      child:
                          Text('按车牌删除', style: themeData.textTheme.bodyMedium),
                    ),
                  ],
                  icon: Icon(Icons.delete, color: themeData.colorScheme.error),
                  tooltip: '删除选项',
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      themeData.colorScheme.primary)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                color: themeData.colorScheme.surfaceContainer,
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
