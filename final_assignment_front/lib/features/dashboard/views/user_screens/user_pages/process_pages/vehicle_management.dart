import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  final TextEditingController _searchController = TextEditingController();
  late VehicleInformationControllerApi vehicleApi;
  final UserDashboardController controller =
  Get.find<UserDashboardController>();
  List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  bool _isUser = true; // 假设为普通用户（USER 角色）
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();
    _loadVehiclesAndCheckRole(); // 异步加载车辆和检查用户角色
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehiclesAndCheckRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 检查用户角色（假设从后端获取）
      final roleResponse = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端提供用户信息
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (roleResponse.statusCode == 200) {
        final roleData = jsonDecode(roleResponse.body);
        _isUser = (roleData['roles'] as List<dynamic>).contains('USER');
        if (!_isUser) {
          throw Exception('权限不足：仅用户可访问此页面');
        }
      } else {
        throw Exception('验证失败：${roleResponse.statusCode} - ${roleResponse.body}');
      }

      await _fetchUserVehicles(); // 仅加载当前用户的车辆
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _fetchUserVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 假设后端通过 JWT 自动过滤当前用户的车辆
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list =
        data.map((json) => VehicleInformation.fromJson(json)).toList();
        setState(() {
          _vehicleList = list;
          _isLoading = false;
        });
      } else {
        throw Exception(
            '加载用户车辆失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载车辆信息失败: $e';
      });
    }
  }

  Future<void> _searchUserVehicles(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      if (query.isEmpty) {
        await _fetchUserVehicles();
        return;
      }

      final isLetter = RegExp(r'[a-zA-Z\u4e00-\u9fa5]').hasMatch(query);

      List<dynamic> rawList = [];
      if (isLetter) {
        // 按车主姓名搜索（仅当前用户的车辆）
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/vehicles/owner/$query'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        if (response.statusCode == 200) {
          rawList = jsonDecode(response.body);
        } else {
          throw Exception('搜索车主失败: ${response.statusCode} - ${response.body}');
        }
      } else {
        // 按车牌号搜索（仅当前用户的车辆）
        final response = await http.get(
          Uri.parse(
              'http://localhost:8081/api/vehicles/license-plate/$query'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          rawList = data is List ? data : [data]; // 假设后端可能返回单条或列表
        } else {
          throw Exception('搜索车牌失败: ${response.statusCode} - ${response.body}');
        }
      }

      final list =
      rawList.map((item) => VehicleInformation.fromJson(item)).toList();
      setState(() {
        _vehicleList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  Future<void> _createVehicle() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehicleEditPage(isNew: true),
      ),
    ).then((value) {
      if (value == true) {
        _fetchUserVehicles(); // 刷新列表
      }
    });
  }

  Future<void> _deleteVehicle(int? vehicleId) async {
    if (vehicleId == null) {
      _showErrorSnackBar('无效的车辆ID');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      // 确保只删除当前用户的车辆（后端通过 JWT 过滤）
      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) { // 204 No Content 表示成功删除
        _showSuccessSnackBar('车辆删除成功');
        _fetchUserVehicles(); // 刷新列表
      } else {
        throw Exception(
            '删除失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isUser) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆管理'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索车辆',
                hintText: '输入车牌号或车主姓名',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              onChanged: (value) {
                _searchUserVehicles(value);
              },
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _vehicleList.isEmpty
                    ? Center(
                  child: Text(
                    '暂无车辆信息',
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: _vehicleList.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicleList[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 4,
                      color: isLight ? Colors.white : Colors.grey[800],
                      child: ListTile(
                        title: Text(
                          '车牌号: ${vehicle.licensePlate ?? ""}',
                          style: TextStyle(
                            color:
                            isLight ? Colors.black87 : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '车主: ${vehicle.ownerName ?? ""}\n车辆类型: ${vehicle.vehicleType ?? ""}',
                          style: TextStyle(
                            color:
                            isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                        onTap: () => _goToDetailPage(vehicle),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VehicleEditPage(vehicle: vehicle),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _fetchUserVehicles(); // 刷新列表
                                }
                              });
                            } else if (value == 'delete') {
                              _deleteVehicle(vehicle.vehicleId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('编辑'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('删除'),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: isLight ? Colors.black87 : Colors.white,
                          ),
                        ),
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

/// 车辆编辑/创建页面
class VehicleEditPage extends StatefulWidget {
  final VehicleInformation? vehicle;
  final bool isNew;

  const VehicleEditPage({super.key, this.vehicle, this.isNew = false});

  @override
  State<VehicleEditPage> createState() => _VehicleEditPageState();
}

class _VehicleEditPageState extends State<VehicleEditPage> {
  late VehicleInformationControllerApi vehicleApi;
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

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();
    _initializeFields();
  }

  void _initializeFields() {
    if (!widget.isNew && widget.vehicle != null) {
      _licensePlateController.text = widget.vehicle!.licensePlate ?? '';
      _vehicleTypeController.text = widget.vehicle!.vehicleType ?? '';
      _ownerNameController.text = widget.vehicle!.ownerName ?? '';
      _idCardNumberController.text = widget.vehicle!.idCardNumber ?? '';
      _contactNumberController.text = widget.vehicle!.contactNumber ?? '';
      _engineNumberController.text = widget.vehicle!.engineNumber ?? '';
      _frameNumberController.text = widget.vehicle!.frameNumber ?? '';
      _vehicleColorController.text = widget.vehicle!.vehicleColor ?? '';
      _firstRegistrationDateController.text =
          widget.vehicle!.firstRegistrationDate ?? '';
      _currentStatusController.text = widget.vehicle!.currentStatus ?? '';
    }
  }

  Future<void> _saveVehicle() async {
    final vehicleInfo = VehicleInformation(
      vehicleId: widget.vehicle?.vehicleId,
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

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final url = widget.isNew
          ? 'http://localhost:8081/api/vehicles'
          : 'http://localhost:8081/api/vehicles/${widget.vehicle!.vehicleId}';
      final method = widget.isNew ? http.post : http.put;
      final idempotencyKey = generateIdempotencyKey(); // 生成幂等键

      final response = await method(
        Uri.parse('$url?idempotencyKey=$idempotencyKey'), // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(vehicleInfo.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessSnackBar(widget.isNew ? '车辆创建成功' : '车辆更新成功');
        Navigator.pop(context, true); // 返回并刷新列表
      } else {
        throw Exception(
            '保存失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('保存失败: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '创建车辆' : '编辑车辆'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _licensePlateController,
              decoration: InputDecoration(
                labelText: '车牌号',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _vehicleTypeController,
              decoration: InputDecoration(
                labelText: '车辆类型',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _ownerNameController,
              decoration: InputDecoration(
                labelText: '车主姓名',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _idCardNumberController,
              decoration: InputDecoration(
                labelText: '身份证号码',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _contactNumberController,
              decoration: InputDecoration(
                labelText: '联系电话',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _engineNumberController,
              decoration: InputDecoration(
                labelText: '发动机号',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _frameNumberController,
              decoration: InputDecoration(
                labelText: '车架号',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _vehicleColorController,
              decoration: InputDecoration(
                labelText: '车身颜色',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _firstRegistrationDateController,
              decoration: InputDecoration(
                labelText: '首次注册日期',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
              readOnly: true,
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                  builder: (context, child) => Theme(
                    data: ThemeData(
                      primaryColor: isLight ? Colors.blue : Colors.blueGrey,
                      colorScheme: ColorScheme.light(
                        primary: isLight ? Colors.blue : Colors.blueGrey,
                      ).copyWith(
                          secondary: isLight ? Colors.blue : Colors.blueGrey),
                    ),
                    child: child!,
                  ),
                );
                if (pickedDate != null) {
                  setState(() {
                    _firstRegistrationDateController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _currentStatusController,
              decoration: InputDecoration(
                labelText: '当前状态',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.grey : Colors.grey[500]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight ? Colors.blue : Colors.blueGrey,
                  ),
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _saveVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(widget.isNew ? '创建车辆' : '保存修改'),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.grey,
                foregroundColor: isLight ? Colors.black87 : Colors.white,
              ),
              child: const Text('返回上一级'),
            ),
          ],
        ),
      ),
    );
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
}

/// 车辆详情页面
class VehicleDetailPage extends StatelessWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildRow(context, '车牌号', vehicle.licensePlate),
            _buildRow(context, '车辆类型', vehicle.vehicleType),
            _buildRow(context, '车主姓名', vehicle.ownerName),
            _buildRow(context, '身份证号码', vehicle.idCardNumber),
            _buildRow(context, '联系电话', vehicle.contactNumber),
            _buildRow(context, '发动机号', vehicle.engineNumber),
            _buildRow(context, '车架号', vehicle.frameNumber),
            _buildRow(context, '车身颜色', vehicle.vehicleColor),
            _buildRow(context, '首次注册日期', vehicle.firstRegistrationDate),
            _buildRow(context, '当前状态', vehicle.currentStatus),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleEditPage(vehicle: vehicle),
            ),
          ).then((value) {
            if (value == true) {
              // 假设父页面会刷新车辆列表
            }
          });
        },
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        tooltip: '编辑车辆',
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String? value) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '无数据',
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}