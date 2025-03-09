import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:get/Get.dart';
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
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentUsername;

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
    _fetchUserVehicles();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final vehicles = await vehicleApi.apiVehiclesGet();
      setState(() {
        _vehicleList =
            vehicles.where((v) => v.ownerName == _currentUsername).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取车辆信息失败: $e';
      });
    }
  }

  Future<void> _searchVehicles(String type, String query) async {
    if (query.isEmpty) {
      await _fetchUserVehicles();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      switch (type) {
        case 'licensePlate':
          final vehicle = await vehicleApi
              .apiVehiclesLicensePlateLicensePlateGet(licensePlate: query);
          setState(() {
            _vehicleList =
                (vehicle != null && vehicle.ownerName == _currentUsername)
                    ? [vehicle]
                    : [];
            _isLoading = false;
            if (vehicle == null) {
              _errorMessage = '未找到车牌号为 $query 的车辆';
            }
          });
          break;
        case 'vehicleType':
          final vehicles = await vehicleApi.apiVehiclesTypeVehicleTypeGet(
              vehicleType: query);
          setState(() {
            _vehicleList =
                vehicles.where((v) => v.ownerName == _currentUsername).toList();
            _isLoading = false;
            if (_vehicleList.isEmpty) {
              _errorMessage = '未找到类型为 $query 的车辆';
            }
          });
          break;
        case 'ownerName':
          final vehicles =
              await vehicleApi.apiVehiclesOwnerOwnerNameGet(ownerName: query);
          setState(() {
            _vehicleList =
                vehicles.where((v) => v.ownerName == _currentUsername).toList();
            _isLoading = false;
            if (_vehicleList.isEmpty) {
              _errorMessage = '未找到车主为 $query 的车辆';
            }
          });
          break;
        case 'currentStatus':
          final vehicles = await vehicleApi.apiVehiclesStatusCurrentStatusGet(
              currentStatus: query);
          setState(() {
            _vehicleList =
                vehicles.where((v) => v.ownerName == _currentUsername).toList();
            _isLoading = false;
            if (_vehicleList.isEmpty) {
              _errorMessage = '未找到状态为 $query 的车辆';
            }
          });
          break;
        default:
          setState(() {
            _errorMessage = '无效的搜索类型';
            _isLoading = false;
          });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '搜索失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createVehicle() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) {
        _fetchUserVehicles();
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
        _fetchUserVehicles();
      }
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchUserVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    try {
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
      _fetchUserVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildSearchField(String label, TextEditingController controller,
      String type, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon:
                    Icon(Icons.search, color: themeData.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: themeData.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeData.colorScheme.primary),
                ),
                labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
              ),
              style: TextStyle(color: themeData.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _searchVehicles(type, controller.text.trim()),
            style: themeData.elevatedButtonTheme.style?.copyWith(
              backgroundColor:
                  WidgetStateProperty.all(themeData.colorScheme.primary),
              foregroundColor:
                  WidgetStateProperty.all(themeData.colorScheme.onPrimary),
            ),
            child: const Text('搜索'),
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
          child: Text(
            _errorMessage,
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆信息列表', style: themeData.textTheme.titleLarge),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: themeData.colorScheme.onPrimaryContainer),
            onPressed: _createVehicle,
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchField(
                '按车牌号搜索', _licensePlateController, 'licensePlate', themeData),
            _buildSearchField(
                '按车辆类型搜索', _vehicleTypeController, 'vehicleType', themeData),
            _buildSearchField(
                '按车主名称搜索', _ownerNameController, 'ownerName', themeData),
            _buildSearchField(
                '按状态搜索', _statusController, 'currentStatus', themeData),
            const SizedBox(height: 16),
            _isLoading
                ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: themeData.colorScheme.primary,
                      ),
                    ),
                  )
                : _vehicleList.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Text(
                            '暂无车辆信息',
                            style: themeData.textTheme.bodyLarge?.copyWith(
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _vehicleList.length,
                          itemBuilder: (context, index) {
                            final vehicle = _vehicleList[index];
                            final type = vehicle.vehicleType ?? '未知类型';
                            final plate = vehicle.licensePlate ?? '未知车牌';
                            final owner = vehicle.ownerName ?? '未知车主';
                            final vid = vehicle.vehicleId ?? 0;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              elevation: 4,
                              color: themeData.colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  '车辆类型: $type',
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  '车牌号: $plate\n车主: $owner',
                                  style:
                                      themeData.textTheme.bodyMedium?.copyWith(
                                    color:
                                        themeData.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _goToDetailPage(vehicle);
                                    } else if (value == 'delete') {
                                      _deleteVehicle(vid);
                                    } else if (value == 'deleteByPlate') {
                                      _deleteVehicleByLicensePlate(plate);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                        value: 'edit', child: Text('编辑')),
                                    const PopupMenuItem<String>(
                                        value: 'delete', child: Text('按ID删除')),
                                    const PopupMenuItem<String>(
                                        value: 'deleteByPlate',
                                        child: Text('按车牌删除')),
                                  ],
                                  icon: Icon(Icons.more_vert,
                                      color: themeData.colorScheme.onSurface),
                                ),
                                onTap: () => _goToDetailPage(vehicle),
                              ),
                            );
                          },
                        ),
                      ),
          ],
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
    vehicleApi.initializeWithJwt();
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
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        firstRegistrationDate: firstRegistrationDate,
        currentStatus: _currentStatusController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      final createdVehicle = await vehicleApi.apiVehiclesPost(
        vehicleInformation: vehicle,
        idempotencyKey: vehicle.idempotencyKey!,
      );

      final findAfterCreatedVehicle = await vehicleApi.apiVehiclesVehicleIdGet(
        vehicleId: createdVehicle.vehicleId!,
      );

      _showSnackBar('创建车辆成功！车辆ID: $findAfterCreatedVehicle');
      if (mounted) {
        Navigator.pop(context, true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailPage(vehicle: createdVehicle),
          ),
        );
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
        content: Text(message),
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
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _firstRegistrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: themeData.colorScheme.primary),
          ),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(color: themeData.colorScheme.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('添加新车辆信息', style: themeData.textTheme.titleLarge),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: themeData.colorScheme.primary))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('车牌号', _licensePlateController, themeData),
                    _buildTextField('车辆类型', _vehicleTypeController, themeData),
                    _buildTextField('车主姓名', _ownerNameController, themeData),
                    _buildTextField('身份证号码', _idCardNumberController, themeData,
                        keyboardType: TextInputType.number),
                    _buildTextField('联系电话', _contactNumberController, themeData,
                        keyboardType: TextInputType.phone),
                    _buildTextField('发动机号', _engineNumberController, themeData),
                    _buildTextField('车架号', _frameNumberController, themeData),
                    _buildTextField('车身颜色', _vehicleColorController, themeData),
                    _buildTextField(
                        '首次注册日期', _firstRegistrationDateController, themeData,
                        readOnly: true, onTap: _pickDate),
                    _buildTextField(
                        '当前状态', _currentStatusController, themeData),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitVehicle,
                      style: themeData.elevatedButtonTheme.style?.copyWith(
                        minimumSize:
                            WidgetStateProperty.all(const Size.fromHeight(50)),
                      ),
                      child: const Text('提交'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: themeData.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                            themeData.colorScheme.secondary),
                        foregroundColor: WidgetStateProperty.all(
                            themeData.colorScheme.onSecondary),
                        minimumSize:
                            WidgetStateProperty.all(const Size.fromHeight(50)),
                      ),
                      child: const Text('返回上一级'),
                    ),
                  ],
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
        contactNumber: _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        firstRegistrationDate: firstRegistrationDate,
        currentStatus: _currentStatusController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicleInformation: vehicle,
        idempotencyKey: vehicle.idempotencyKey!,
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
        content: Text(message),
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
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _firstRegistrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: themeData.colorScheme.primary),
          ),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(color: themeData.colorScheme.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('编辑车辆信息', style: themeData.textTheme.titleLarge),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: themeData.colorScheme.primary))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('车牌号', _licensePlateController, themeData),
                    _buildTextField('车辆类型', _vehicleTypeController, themeData),
                    _buildTextField('车主姓名', _ownerNameController, themeData),
                    _buildTextField('身份证号码', _idCardNumberController, themeData,
                        keyboardType: TextInputType.number),
                    _buildTextField('联系电话', _contactNumberController, themeData,
                        keyboardType: TextInputType.phone),
                    _buildTextField('发动机号', _engineNumberController, themeData),
                    _buildTextField('车架号', _frameNumberController, themeData),
                    _buildTextField('车身颜色', _vehicleColorController, themeData),
                    _buildTextField(
                        '首次注册日期', _firstRegistrationDateController, themeData,
                        readOnly: true, onTap: _pickDate),
                    _buildTextField(
                        '当前状态', _currentStatusController, themeData),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitVehicle,
                      style: themeData.elevatedButtonTheme.style?.copyWith(
                        minimumSize:
                            WidgetStateProperty.all(const Size.fromHeight(50)),
                      ),
                      child: const Text('保存'),
                    ),
                  ],
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
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final currentUsername = prefs.getString('userName');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = roleData['roles'] as List<dynamic>;
        final username = roleData['sub'];
        setState(() {
          _isEditable =
              roles.contains('ADMIN') || (username == widget.vehicle.ownerName);
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
      });
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
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        body: Center(
          child: Text(
            _errorMessage,
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆详细信息', style: themeData.textTheme.titleLarge),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        actions: _isEditable
            ? [
                IconButton(
                  icon: Icon(Icons.edit,
                      color: themeData.colorScheme.onPrimaryContainer),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteVehicle(widget.vehicle.vehicleId ?? 0);
                    } else if (value == 'deleteByPlate') {
                      _deleteVehicleByLicensePlate(
                          widget.vehicle.licensePlate ?? '');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                        value: 'delete', child: Text('按ID删除')),
                    const PopupMenuItem<String>(
                        value: 'deleteByPlate', child: Text('按车牌删除')),
                  ],
                  icon: Icon(Icons.delete, color: themeData.colorScheme.error),
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: themeData.colorScheme.primary))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(
                      '车辆类型', widget.vehicle.vehicleType ?? '未知类型', themeData),
                  _buildDetailRow(
                      '车牌号', widget.vehicle.licensePlate ?? '未知车牌', themeData),
                  _buildDetailRow(
                      '车主姓名', widget.vehicle.ownerName ?? '未知车主', themeData),
                  _buildDetailRow(
                      '车辆状态', widget.vehicle.currentStatus ?? '无', themeData),
                  _buildDetailRow(
                      '身份证号码', widget.vehicle.idCardNumber ?? '无', themeData),
                  _buildDetailRow(
                      '联系电话', widget.vehicle.contactNumber ?? '无', themeData),
                  _buildDetailRow(
                      '发动机号', widget.vehicle.engineNumber ?? '无', themeData),
                  _buildDetailRow(
                      '车架号', widget.vehicle.frameNumber ?? '无', themeData),
                  _buildDetailRow(
                      '车身颜色', widget.vehicle.vehicleColor ?? '无', themeData),
                  _buildDetailRow(
                      '首次注册日期',
                      formatDate(widget.vehicle.firstRegistrationDate),
                      themeData),
                ],
              ),
            ),
    );
  }
}
