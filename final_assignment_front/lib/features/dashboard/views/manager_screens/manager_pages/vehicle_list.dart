import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unique identifier generator for idempotency
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// Format date for display
String formatDate(DateTime? date) {
  if (date == null) return '未知日期';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleList> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  List<VehicleInformation> _vehicles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;
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
    if (_currentUsername == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录以查看车辆信息';
      });
      return;
    }
    await vehicleApi.initializeWithJwt();
    _fetchVehicles(reset: true);
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _hasMore = true;
      _vehicles.clear();
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
      );
      setState(() {
        _vehicles.addAll(vehicles);
        _isLoading = false;
        if (vehicles.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '加载车辆信息失败: $e';
      });
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchVehicles();
  }

  Future<void> _searchVehicles(String type, String query) async {
    if (query.isEmpty) {
      await _fetchVehicles(reset: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 0;
      _hasMore = true;
      _vehicles.clear();
    });
    try {
      switch (type) {
        case 'licensePlate':
          final vehicle = await vehicleApi
              .apiVehiclesLicensePlateLicensePlateGet(licensePlate: query);
          setState(() {
            _vehicles = vehicle != null ? [vehicle] : [];
            _isLoading = false;
            _hasMore = false;
            if (_vehicles.isEmpty) _errorMessage = '未找到车牌号为 $query 的车辆';
          });
          break;
        case 'vehicleType':
          final vehicles = await vehicleApi.apiVehiclesTypeVehicleTypeGet(
            vehicleType: query,
            page: _currentPage,
            size: _pageSize,
          );
          setState(() {
            _vehicles = vehicles;
            _isLoading = false;
            if (vehicles.length < _pageSize) _hasMore = false;
            if (_vehicles.isEmpty) _errorMessage = '未找到类型为 $query 的车辆';
          });
          break;
        case 'ownerName':
          final vehicles = await vehicleApi.apiVehiclesOwnerOwnerNameGet(
            ownerName: query,
            page: _currentPage,
            size: _pageSize,
          );
          setState(() {
            _vehicles = vehicles;
            _isLoading = false;
            if (vehicles.length < _pageSize) _hasMore = false;
            if (_vehicles.isEmpty) _errorMessage = '未找到车主为 $query 的车辆';
          });
          break;
        case 'status':
          final vehicles = await vehicleApi.apiVehiclesStatusCurrentStatusGet(
            currentStatus: query,
            page: _currentPage,
            size: _pageSize,
          );
          setState(() {
            _vehicles = vehicles;
            _isLoading = false;
            if (vehicles.length < _pageSize) _hasMore = false;
            if (_vehicles.isEmpty) _errorMessage = '未找到状态为 $query 的车辆';
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

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    try {
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
      _fetchVehicles(reset: true);
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    borderRadius: BorderRadius.circular(8.0)),
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
              onSubmitted: (value) => _searchVehicles(type, value.trim()),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _searchVehicles(type, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
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
        title: Text('车辆信息列表',
            style: themeData.textTheme.titleLarge
                ?.copyWith(color: themeData.colorScheme.onPrimary)),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
            _buildSearchField('按状态搜索', _statusController, 'status', themeData),
            const SizedBox(height: 16),
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
                    : _vehicles.isEmpty
                        ? Center(
                            child: Text('暂无车辆信息',
                                style: themeData.textTheme.bodyLarge))
                        : ListView.builder(
                            itemCount: _vehicles.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _vehicles.length && _hasMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              final vehicle = _vehicles[index];
                              final type = vehicle.vehicleType ?? '未知类型';
                              final plate = vehicle.licensePlate ?? '未知车牌';
                              final owner = vehicle.ownerName ?? '未知车主';
                              final status = vehicle.currentStatus ?? '未知状态';
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                elevation: 4,
                                color: themeData.colorScheme.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                child: ListTile(
                                  title: Text('车辆类型: $type',
                                      style: themeData.textTheme.bodyLarge),
                                  subtitle: Text(
                                      '车牌号: $plate\n车主: $owner\n状态: $status',
                                      style: themeData.textTheme.bodyMedium),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _goToDetailPage(vehicle);
                                      } else if (value == 'delete') {
                                        _deleteVehicle(vehicle.vehicleId!);
                                      } else if (value == 'deleteByPlate') {
                                        _deleteVehicleByLicensePlate(plate);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                          value: 'edit', child: Text('编辑')),
                                      const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('按ID删除')),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createVehicle,
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '添加新车辆信息',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation? vehicle;

  const VehicleDetailPage({super.key, this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final bool _isLoading = false;
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
    vehicleApi.initializeWithJwt();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        // Adjust URL as per your backend
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = roleData['roles'] as List<dynamic>;
        setState(() {
          _isEditable = roles.contains('ADMIN') || roles.contains('USER');
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载权限失败: $e';
      });
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

  void _editVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVehiclePage(vehicle: widget.vehicle!)),
    ).then((value) {
      if (value == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: themeData.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: themeData.textTheme.bodyMedium),
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
          child: Text(_errorMessage, style: themeData.textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆详细信息',
            style: themeData.textTheme.titleLarge
                ?.copyWith(color: themeData.colorScheme.onPrimary)),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        actions: _isEditable && widget.vehicle != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editVehicle,
                  tooltip: '编辑车辆信息',
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(
                      '车辆类型', widget.vehicle?.vehicleType ?? '未知', themeData),
                  _buildDetailRow(
                      '车牌号', widget.vehicle?.licensePlate ?? '未知', themeData),
                  _buildDetailRow(
                      '车主姓名', widget.vehicle?.ownerName ?? '未知', themeData),
                  _buildDetailRow(
                      '身份证号码', widget.vehicle?.idCardNumber ?? '未知', themeData),
                  _buildDetailRow(
                      '联系电话', widget.vehicle?.contactNumber ?? '未知', themeData),
                  _buildDetailRow(
                      '发动机号', widget.vehicle?.engineNumber ?? '未知', themeData),
                  _buildDetailRow(
                      '车架号', widget.vehicle?.frameNumber ?? '未知', themeData),
                  _buildDetailRow(
                      '车身颜色', widget.vehicle?.vehicleColor ?? '未知', themeData),
                  _buildDetailRow(
                      '首次注册日期',
                      formatDate(widget.vehicle?.firstRegistrationDate),
                      themeData),
                  _buildDetailRow(
                      '当前状态', widget.vehicle?.currentStatus ?? '未知', themeData),
                ],
              ),
            ),
    );
  }
}

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _plateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _idCardController = TextEditingController();
  final _contactController = TextEditingController();
  final _engineController = TextEditingController();
  final _frameController = TextEditingController();
  final _colorController = TextEditingController();
  final _registrationDateController = TextEditingController();
  final _statusController = TextEditingController();
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
    _typeController.dispose();
    _plateController.dispose();
    _ownerController.dispose();
    _idCardController.dispose();
    _contactController.dispose();
    _engineController.dispose();
    _frameController.dispose();
    _colorController.dispose();
    _registrationDateController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      DateTime? registrationDate;
      if (_registrationDateController.text.isNotEmpty) {
        registrationDate =
            DateTime.parse(_registrationDateController.text.trim());
      }

      final vehicle = VehicleInformation(
        vehicleType: _typeController.text.trim(),
        licensePlate: _plateController.text.trim(),
        ownerName: _ownerController.text.trim(),
        idCardNumber: _idCardController.text.trim(),
        contactNumber: _contactController.text.trim(),
        engineNumber: _engineController.text.trim(),
        frameNumber: _frameController.text.trim(),
        vehicleColor: _colorController.text.trim(),
        firstRegistrationDate: registrationDate,
        currentStatus: _statusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesPost(
        vehicleInformation: vehicle,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建车辆记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建车辆记录失败: $e', isError: true);
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _registrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                      _buildTextField('车辆类型', _typeController, themeData,
                          required: true),
                      _buildTextField('车牌号', _plateController, themeData,
                          required: true),
                      _buildTextField('车主姓名', _ownerController, themeData,
                          required: true),
                      _buildTextField('身份证号码', _idCardController, themeData),
                      _buildTextField('联系电话', _contactController, themeData,
                          keyboardType: TextInputType.phone),
                      _buildTextField('发动机号', _engineController, themeData),
                      _buildTextField('车架号', _frameController, themeData),
                      _buildTextField('车身颜色', _colorController, themeData),
                      _buildTextField(
                          '首次注册日期', _registrationDateController, themeData,
                          readOnly: true, onTap: _pickDate),
                      _buildTextField('当前状态', _statusController, themeData),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(50),
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
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _plateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _idCardController = TextEditingController();
  final _contactController = TextEditingController();
  final _engineController = TextEditingController();
  final _frameController = TextEditingController();
  final _colorController = TextEditingController();
  final _registrationDateController = TextEditingController();
  final _statusController = TextEditingController();
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
    _typeController.text = widget.vehicle.vehicleType ?? '';
    _plateController.text = widget.vehicle.licensePlate ?? '';
    _ownerController.text = widget.vehicle.ownerName ?? '';
    _idCardController.text = widget.vehicle.idCardNumber ?? '';
    _contactController.text = widget.vehicle.contactNumber ?? '';
    _engineController.text = widget.vehicle.engineNumber ?? '';
    _frameController.text = widget.vehicle.frameNumber ?? '';
    _colorController.text = widget.vehicle.vehicleColor ?? '';
    _registrationDateController.text =
        formatDate(widget.vehicle.firstRegistrationDate);
    _statusController.text = widget.vehicle.currentStatus ?? '';
  }

  @override
  void dispose() {
    _typeController.dispose();
    _plateController.dispose();
    _ownerController.dispose();
    _idCardController.dispose();
    _contactController.dispose();
    _engineController.dispose();
    _frameController.dispose();
    _colorController.dispose();
    _registrationDateController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      DateTime? registrationDate;
      if (_registrationDateController.text.isNotEmpty) {
        registrationDate =
            DateTime.parse(_registrationDateController.text.trim());
      }

      final updatedVehicle = widget.vehicle.copyWith(
        vehicleType: _typeController.text.trim(),
        licensePlate: _plateController.text.trim(),
        ownerName: _ownerController.text.trim(),
        idCardNumber: _idCardController.text.trim(),
        contactNumber: _contactController.text.trim(),
        engineNumber: _engineController.text.trim(),
        frameNumber: _frameController.text.trim(),
        vehicleColor: _colorController.text.trim(),
        firstRegistrationDate: registrationDate,
        currentStatus: _statusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId!,
        vehicleInformation: updatedVehicle,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('更新车辆记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新车辆记录失败: $e', isError: true);
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _registrationDateController.text = formatDate(pickedDate);
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                      _buildTextField('车辆类型', _typeController, themeData,
                          required: true),
                      _buildTextField('车牌号', _plateController, themeData,
                          required: true),
                      _buildTextField('车主姓名', _ownerController, themeData,
                          required: true),
                      _buildTextField('身份证号码', _idCardController, themeData),
                      _buildTextField('联系电话', _contactController, themeData,
                          keyboardType: TextInputType.phone),
                      _buildTextField('发动机号', _engineController, themeData),
                      _buildTextField('车架号', _frameController, themeData),
                      _buildTextField('车身颜色', _colorController, themeData),
                      _buildTextField(
                          '首次注册日期', _registrationDateController, themeData,
                          readOnly: true, onTap: _pickDate),
                      _buildTextField('当前状态', _statusController, themeData),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(50),
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
