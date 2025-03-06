import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unique identifier generator for idempotency
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleList> {
  late VehicleInformationControllerApi vehicleApi;
  late Future<List<VehicleInformation>> _vehiclesFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';

  // 搜索时使用的控制器
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();
    _checkUserRole();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  /// 检查用户角色并设置 JWT 验证
  Future<void> _checkUserRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      // 将 jwtToken 设置到 ApiClient 中
      await vehicleApi.initializeWithJwt();

      // 进行角色验证，此处调用 /api/auth/me 接口验证
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final userRole = (roleData['roles'] as List<dynamic>).firstWhere(
          (role) => role == 'ADMIN',
          orElse: () => 'USER',
        );
        _isAdmin = userRole == 'ADMIN';
        if (_isAdmin) {
          _loadVehicles();
        } else {
          setState(() {
            _errorMessage = '权限不足：仅管理员可访问此页面';
            _isLoading = false;
          });
        }
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _vehiclesFuture = vehicleApi.apiVehiclesGet();
    });
    try {
      await _vehiclesFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载车辆信息失败: $e';
      });
    }
  }

  Future<void> _searchVehicles(String type, String query) async {
    if (query.isEmpty) {
      _loadVehicles();
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
          _vehiclesFuture = Future.value(vehicle != null ? [vehicle] : []);
          break;
        case 'vehicleType':
          _vehiclesFuture =
              vehicleApi.apiVehiclesTypeVehicleTypeGet(vehicleType: query);
          break;
        case 'ownerName':
          _vehiclesFuture =
              vehicleApi.apiVehiclesOwnerOwnerNameGet(ownerName: query);
          break;
        case 'status':
          _vehiclesFuture = vehicleApi.apiVehiclesStatusCurrentStatusGet(
              currentStatus: query);
          break;
        default:
          _loadVehicles();
          return;
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
      ),
    );
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) {
        _loadVehicles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(color: isLight ? Colors.black : Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆信息列表'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVehiclePage()),
              ).then((value) {
                if (value == true && mounted) {
                  _loadVehicles();
                }
              });
            },
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchField(
                '按车牌号搜索', _licensePlateController, 'licensePlate', isLight),
            _buildSearchField(
                '按车辆类型搜索', _vehicleTypeController, 'vehicleType', isLight),
            _buildSearchField(
                '按车主名称搜索', _ownerNameController, 'ownerName', isLight),
            _buildSearchField('按状态搜索', _statusController, 'status', isLight),
            const SizedBox(height: 16),
            _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _errorMessage.isNotEmpty
                    ? Expanded(child: Center(child: Text(_errorMessage)))
                    : Expanded(
                        child: FutureBuilder<List<VehicleInformation>>(
                          future: _vehiclesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  '加载车辆信息时发生错误: ${snapshot.error}',
                                  style: TextStyle(
                                      color: isLight
                                          ? Colors.black
                                          : Colors.white),
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  '没有找到车辆信息',
                                  style: TextStyle(
                                      color: isLight
                                          ? Colors.black
                                          : Colors.white),
                                ),
                              );
                            } else {
                              final vehicles = snapshot.data!;
                              return ListView.builder(
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final v = vehicles[index];
                                  final type = v.vehicleType ?? '未知类型';
                                  final plate = v.licensePlate ?? '未知车牌';
                                  final owner = v.ownerName ?? '未知车主';
                                  final vid = v.vehicleId ?? 0;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    elevation: 4,
                                    color: isLight
                                        ? Colors.white
                                        : Colors.grey[800],
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0)),
                                    child: ListTile(
                                      title: Text('车辆类型: $type',
                                          style: TextStyle(
                                              color: isLight
                                                  ? Colors.black87
                                                  : Colors.white)),
                                      subtitle: Text('车牌号: $plate\n车主: $owner',
                                          style: TextStyle(
                                              color: isLight
                                                  ? Colors.black54
                                                  : Colors.white70)),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _goToDetailPage(v);
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
                                              value: 'delete',
                                              child: Text('按ID删除')),
                                          const PopupMenuItem<String>(
                                              value: 'deleteByPlate',
                                              child: Text('按车牌删除')),
                                        ],
                                        icon: Icon(Icons.more_vert,
                                            color: isLight
                                                ? Colors.black87
                                                : Colors.white),
                                      ),
                                      onTap: () => _goToDetailPage(v),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(String label, TextEditingController controller,
      String type, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                labelStyle:
                    TextStyle(color: isLight ? Colors.black87 : Colors.white),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isLight ? Colors.grey : Colors.grey[500]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isLight ? Colors.blue : Colors.blueGrey)),
              ),
              onChanged: (value) => _searchVehicles(type, value),
              style: TextStyle(color: isLight ? Colors.black : Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _searchVehicles(type, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _loadVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    try {
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
      _loadVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }
}

/// ==================== 添加与编辑车辆页面 ====================

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final vehicleApi = VehicleInformationControllerApi();
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

  @override
  void initState() {
    super.initState();
    // 如需要确保 JWT 已设置，可在此调用 initializeWithJwt()
    // await vehicleApi.initializeWithJwt();
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
    setState(() {
      _isLoading = true;
    });
    try {
      final vehicle = VehicleInformation(
        licensePlate: _licensePlateController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        firstRegistrationDate: _firstRegistrationDateController.text.trim(),
        currentStatus: _currentStatusController.text.trim(),
      );
      await vehicleApi.apiVehiclesPost(
        vehicleInformation: vehicle,
        idempotencyKey: generateIdempotencyKey(),
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
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
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
        _firstRegistrationDateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isLight,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
          enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!)),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isLight ? Colors.blue : Colors.blueGrey)),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(color: isLight ? Colors.black : Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新车辆信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('车牌号', _licensePlateController, isLight),
                    _buildTextField('车辆类型', _vehicleTypeController, isLight),
                    _buildTextField('车主姓名', _ownerNameController, isLight),
                    _buildTextField('身份证号码', _idCardNumberController, isLight,
                        keyboardType: TextInputType.number),
                    _buildTextField('联系电话', _contactNumberController, isLight,
                        keyboardType: TextInputType.phone),
                    _buildTextField('发动机号', _engineNumberController, isLight),
                    _buildTextField('车架号', _frameNumberController, isLight),
                    _buildTextField('车身颜色', _vehicleColorController, isLight),
                    _buildTextField(
                      '首次注册日期',
                      _firstRegistrationDateController,
                      isLight,
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                    _buildTextField('当前状态', _currentStatusController, isLight),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('提交'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.grey,
                        foregroundColor:
                            isLight ? Colors.black87 : Colors.white,
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

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final vehicleApi = VehicleInformationControllerApi();
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

  @override
  void initState() {
    super.initState();
    _initializeFields();
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
        widget.vehicle.firstRegistrationDate ?? '';
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
    setState(() {
      _isLoading = true;
    });
    try {
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
        firstRegistrationDate: _firstRegistrationDateController.text.trim(),
        currentStatus: _currentStatusController.text.trim(),
      );
      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicleInformation: vehicle,
        idempotencyKey: generateIdempotencyKey(),
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
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
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
        _firstRegistrationDateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isLight,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
          enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!)),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isLight ? Colors.blue : Colors.blueGrey)),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(color: isLight ? Colors.black : Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑车辆信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('车牌号', _licensePlateController, isLight),
                    _buildTextField('车辆类型', _vehicleTypeController, isLight),
                    _buildTextField('车主姓名', _ownerNameController, isLight),
                    _buildTextField('身份证号码', _idCardNumberController, isLight,
                        keyboardType: TextInputType.number),
                    _buildTextField('联系电话', _contactNumberController, isLight,
                        keyboardType: TextInputType.phone),
                    _buildTextField('发动机号', _engineNumberController, isLight),
                    _buildTextField('车架号', _frameNumberController, isLight),
                    _buildTextField('车身颜色', _vehicleColorController, isLight),
                    _buildTextField(
                      '首次注册日期',
                      _firstRegistrationDateController,
                      isLight,
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                    _buildTextField('当前状态', _currentStatusController, isLight),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('保存'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.grey,
                        foregroundColor:
                            isLight ? Colors.black87 : Colors.white,
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

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final vehicleApi = VehicleInformationControllerApi();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      // 将 jwtToken 设置到 ApiClient 中
      await vehicleApi.initializeWithJwt();
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        setState(() {});
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
    setState(() {
      _isLoading = true;
    });
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
    setState(() {
      _isLoading = true;
    });
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
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black87 : Colors.white)),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white70))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage,
              style: TextStyle(color: isLight ? Colors.black : Colors.white)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆详细信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: _isAdmin
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
                        Navigator.pop(
                            context, true); // Trigger refresh in parent
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
                  icon: Icon(Icons.delete,
                      color: isLight ? Colors.red : Colors.red[300]),
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
                      '车辆类型', widget.vehicle.vehicleType ?? '未知类型', isLight),
                  _buildDetailRow(
                      '车牌号', widget.vehicle.licensePlate ?? '未知车牌', isLight),
                  _buildDetailRow(
                      '车主姓名', widget.vehicle.ownerName ?? '未知车主', isLight),
                  _buildDetailRow(
                      '车辆状态', widget.vehicle.currentStatus ?? '无', isLight),
                  _buildDetailRow(
                      '身份证号码', widget.vehicle.idCardNumber ?? '无', isLight),
                  _buildDetailRow(
                      '联系电话', widget.vehicle.contactNumber ?? '无', isLight),
                  _buildDetailRow(
                      '发动机号', widget.vehicle.engineNumber ?? '无', isLight),
                  _buildDetailRow(
                      '车架号', widget.vehicle.frameNumber ?? '无', isLight),
                  _buildDetailRow(
                      '车身颜色', widget.vehicle.vehicleColor ?? '无', isLight),
                  _buildDetailRow('首次注册日期',
                      widget.vehicle.firstRegistrationDate ?? '无', isLight),
                ],
              ),
            ),
    );
  }
}

Widget _buildTextField(
    String label, TextEditingController controller, bool isLight,
    {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
        enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!)),
        focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: isLight ? Colors.blue : Colors.blueGrey)),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: isLight ? Colors.black : Colors.white),
    ),
  );
}
