// 根据你的项目实际路径修改
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
  bool _isAdmin = false; // 假设从状态管理或 SharedPreferences 获取
  String _errorMessage = '';
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();
    _checkUserRole(); // 检查用户角色并加载车辆
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
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

      setState(() {
        _isAdmin = userRole == 'ADMIN';
        if (_isAdmin) {
          _loadVehicles(); // 仅管理员加载所有车辆
        } else {
          _errorMessage = '权限不足：仅管理员可访问此页面';
          _isLoading = false;
        }
      });
    } else {
      setState(() {
        _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVehicles() async {
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

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final vehicles =
            data.map((json) => VehicleInformation.fromJson(json)).toList();
        setState(() {
          _vehiclesFuture = Future.value(vehicles);
          _isLoading = false;
        });
      } else {
        throw Exception('加载车辆信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载车辆信息失败: $e';
      });
    }
  }

  Future<void> _searchVehicles(String type, String query) async {
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

      Uri uri;
      switch (type) {
        case 'licensePlate':
          uri = Uri.parse(
              'http://localhost:8081/api/vehicles/license-plate/$query');
          break;
        case 'vehicleType':
          uri = Uri.parse('http://localhost:8081/api/vehicles/type/$query');
          break;
        case 'ownerName':
          uri = Uri.parse('http://localhost:8081/api/vehicles/owner/$query');
          break;
        case 'status':
          uri = Uri.parse('http://localhost:8081/api/vehicles/status/$query');
          break;
        default:
          await _loadVehicles();
          return;
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final vehicles = _parseVehicleResult(data);
        setState(() {
          _vehiclesFuture = Future.value(vehicles);
          _isLoading = false;
        });
      } else {
        throw Exception('搜索失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  Future<void> _createVehicle(VehicleInformation vehicle) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final idempotencyKey = generateIdempotencyKey();
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/vehicles?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建车辆成功！')),
        );
        _loadVehicles(); // 刷新列表
      } else {
        throw Exception('创建失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('创建失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _updateVehicle(int vehicleId, VehicleInformation vehicle) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final idempotencyKey = generateIdempotencyKey();
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/vehicles/$vehicleId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        // 200 OK
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新车辆成功！')),
        );
        _loadVehicles(); // 刷新列表
      } else {
        throw Exception('更新失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除车辆成功！')),
        );
        _loadVehicles(); // 刷新列表
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse(
            'http://localhost:8081/api/vehicles/license-plate/$licensePlate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('按车牌删除车辆成功！')),
        );
        _loadVehicles(); // 刷新列表
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<bool> _isLicensePlateExists(String licensePlate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/vehicles/exists/$licensePlate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final bool exists = jsonDecode(response.body) as bool;
        return exists;
      } else {
        throw Exception(
            '检查车牌是否存在失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('检查车牌是否存在失败: $e');
      return false;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  List<VehicleInformation> _parseVehicleResult(dynamic result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) =>
              VehicleInformation.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [VehicleInformation.fromJson(result)];
    }
    return [];
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadVehicles(); // 详情页更新后刷新列表，确保 widget 仍然挂载
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isAdmin) {
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
        title: const Text('车辆信息列表'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _licensePlateController,
                    decoration: InputDecoration(
                      labelText: '按车牌号搜索',
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
                    onChanged: (value) =>
                        _searchVehicles('licensePlate', value),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchVehicles(
                      'licensePlate', _licensePlateController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vehicleTypeController,
                    decoration: InputDecoration(
                      labelText: '按车辆类型搜索',
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
                    onChanged: (value) => _searchVehicles('vehicleType', value),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchVehicles(
                      'vehicleType', _vehicleTypeController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(
                      labelText: '按车主名称搜索',
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
                    onChanged: (value) => _searchVehicles('ownerName', value),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchVehicles(
                      'ownerName', _ownerNameController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _statusController,
                    decoration: InputDecoration(
                      labelText: '按状态搜索',
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
                    onChanged: (value) => _searchVehicles('status', value),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _searchVehicles('status', _statusController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(child: Center(child: Text(_errorMessage)))
            else
              Expanded(
                child: FutureBuilder<List<VehicleInformation>>(
                  future: _vehiclesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '加载车辆信息时发生错误: ${snapshot.error}',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          '没有找到车辆信息',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
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
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                '车辆类型: $type',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '车牌号: $plate\n车主: $owner',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
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
                                    value: 'edit',
                                    child: Text('编辑'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('按ID删除'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'deleteByPlate',
                                    child: Text('按车牌删除'),
                                  ),
                                ],
                                icon: Icon(
                                  Icons.more_vert,
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
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
}

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _frameNumberController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _firstRegistrationDateController =
      TextEditingController();
  final TextEditingController _currentStatusController =
      TextEditingController();
  bool _isLoading = false;

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
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = VehicleInformation(
        vehicleId: null,
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
        idempotencyKey:
            generateIdempotencyKey(), // Add idempotencyKey for new records
      );

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/vehicles?idempotencyKey=${generateIdempotencyKey()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 201) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建车辆成功！')),
        );
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('创建失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('创建车辆失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
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
        title: const Text('添加新车辆信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
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
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                              primaryColor:
                                  isLight ? Colors.blue : Colors.blueGrey,
                              colorScheme: ColorScheme.light(
                                primary:
                                    isLight ? Colors.blue : Colors.blueGrey,
                              ).copyWith(
                                  secondary:
                                      isLight ? Colors.blue : Colors.blueGrey),
                            ),
                            child: child!,
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() {
                            _firstRegistrationDateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
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
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _frameNumberController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _firstRegistrationDateController =
      TextEditingController();
  final TextEditingController _currentStatusController =
      TextEditingController();
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
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
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
        idempotencyKey: widget.vehicle.idempotencyKey ??
            generateIdempotencyKey(), // Reuse or generate new
      );

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/vehicles/${widget.vehicle.vehicleId}?idempotencyKey=${generateIdempotencyKey()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新车辆成功！')),
        );
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('更新失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新车辆失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
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
        title: const Text('编辑车辆信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
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
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                              primaryColor:
                                  isLight ? Colors.blue : Colors.blueGrey,
                              colorScheme: ColorScheme.light(
                                primary:
                                    isLight ? Colors.blue : Colors.blueGrey,
                              ).copyWith(
                                  secondary:
                                      isLight ? Colors.blue : Colors.blueGrey),
                            ),
                            child: child!,
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() {
                            _firstRegistrationDateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
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
  bool _isLoading = false;
  bool _isAdmin = false; // 管理员权限标识
  String _errorMessage = ''; // 错误消息

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
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

      setState(() {
        _isAdmin = userRole == 'ADMIN';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除车辆成功！')),
        );
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse(
            'http://localhost:8081/api/vehicles/license-plate/$licensePlate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('按车牌删除车辆成功！')),
        );
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
              value,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    final type = widget.vehicle.vehicleType ?? '未知类型';
    final plate = widget.vehicle.licensePlate ?? '未知车牌';
    final owner = widget.vehicle.ownerName ?? '未知车主';

    if (_errorMessage.isNotEmpty) {
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
        title: const Text('车辆详细信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          if (_isAdmin) // 仅 ADMIN 显示编辑和删除按钮
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditVehiclePage(vehicle: widget.vehicle),
                  ),
                ).then((value) {
                  if (value == true && mounted) {
                    setState(() {});
                  }
                });
              },
              tooltip: '编辑车辆信息',
            ),
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteVehicle(widget.vehicle.vehicleId ?? 0);
                } else if (value == 'deleteByPlate') {
                  _deleteVehicleByLicensePlate(plate);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('按ID删除'),
                ),
                const PopupMenuItem<String>(
                  value: 'deleteByPlate',
                  child: Text('按车牌删除'),
                ),
              ],
              icon: Icon(
                Icons.delete,
                color: isLight ? Colors.red : Colors.red[300],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(context, '车辆类型', type),
                  _buildDetailRow(context, '车牌号', plate),
                  _buildDetailRow(context, '车主姓名', owner),
                  _buildDetailRow(
                      context, '车辆状态', widget.vehicle.currentStatus ?? '无'),
                  _buildDetailRow(
                      context, '身份证号码', widget.vehicle.idCardNumber ?? '无'),
                  _buildDetailRow(
                      context, '联系电话', widget.vehicle.contactNumber ?? '无'),
                  _buildDetailRow(
                      context, '发动机号', widget.vehicle.engineNumber ?? '无'),
                  _buildDetailRow(
                      context, '车架号', widget.vehicle.frameNumber ?? '无'),
                  _buildDetailRow(
                      context, '车身颜色', widget.vehicle.vehicleColor ?? '无'),
                  _buildDetailRow(context, '首次注册日期',
                      widget.vehicle.firstRegistrationDate ?? '无'),
                ],
              ),
            ),
    );
  }
}
