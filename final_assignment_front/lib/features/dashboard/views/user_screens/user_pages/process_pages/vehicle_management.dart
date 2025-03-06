import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 生成幂等性键的全局方法
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  // 定义四个搜索控制器
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
    // 设置 JWT 到 ApiClient
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
          });
          break;
        case 'vehicleType':
          final vehicles = await vehicleApi.apiVehiclesTypeVehicleTypeGet(
              vehicleType: query);
          setState(() {
            _vehicleList =
                vehicles.where((v) => v.ownerName == _currentUsername).toList();
            _isLoading = false;
          });
          break;
        case 'ownerName':
          final vehicles =
              await vehicleApi.apiVehiclesOwnerOwnerNameGet(ownerName: query);
          setState(() {
            _vehicleList =
                vehicles.where((v) => v.ownerName == _currentUsername).toList();
            _isLoading = false;
          });
          break;
        case 'status':
          final vehicles = await vehicleApi.apiVehiclesStatusCurrentStatusGet(
              currentStatus: query);
          setState(() {
            _vehicleList = vehicles;
            _isLoading = false;
          });
          break;
        default:
          _fetchUserVehicles();
          return;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  // 定义创建车辆的方法
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
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    if (!_isLoading && _errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage,
              style: TextStyle(color: isLight ? Colors.black : Colors.white)),
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
                : _vehicleList.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Text('暂无车辆信息',
                              style: TextStyle(
                                  color:
                                      isLight ? Colors.black : Colors.white)),
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
                              color: isLight ? Colors.white : Colors.grey[800],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
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
                                      color: isLight
                                          ? Colors.black87
                                          : Colors.white),
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
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        tooltip: '添加新车辆',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ==================== 添加与编辑车辆页面 ====================

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

  @override
  void initState() {
    super.initState();
    // 若需要确保 ApiClient 已设置 JWT，可在此调用 initializeWithJwt（前提是 jwt 已存储）
    // vehicleApi.initializeWithJwt();
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
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
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
                style:
                    TextStyle(color: isLight ? Colors.black : Colors.white))),
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
                        Navigator.pop(context, true); // 触发父页面刷新
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
