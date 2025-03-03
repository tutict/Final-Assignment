import 'dart:developer' as developer;

import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4(); // 使用 UUID 生成更可靠的唯一标识
}

/// 司机信息列表页面
class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList> {
  late DriverInformationControllerApi driverApi;
  late Future<List<DriverInformation>> _driversFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>(); // 确保导入正确的控制器
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
    _checkUserRole(); // 检查用户角色并加载司机信息
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  /// 检查用户角色
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
          _loadDrivers(); // 仅管理员加载所有司机信息
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

  /// 加载所有司机信息
  Future<void> _loadDrivers() async {
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
        Uri.parse('http://localhost:8081/api/drivers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final drivers =
            data.map((json) => DriverInformation.fromJson(json)).toList();
        setState(() {
          _driversFuture = Future.value(drivers);
          _isLoading = false;
        });
      } else {
        throw Exception('加载司机信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching drivers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载司机信息失败: $e';
      });
    }
  }

  /// 按姓名搜索司机信息
  Future<void> _searchDriversByName(String query) async {
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
        Uri.parse('http://localhost:8081/api/drivers/name/$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final drivers = _parseDriverResult(data);
        setState(() {
          _driversFuture = Future.value(drivers);
          _isLoading = false;
        });
      } else {
        throw Exception('搜索失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error searching drivers by name: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  /// 按身份证号搜索司机信息
  Future<void> _searchDriversByIdCardNumber(String query) async {
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
        Uri.parse('http://localhost:8081/api/drivers/idCardNumber/$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final drivers = _parseDriverResult(data);
        setState(() {
          _driversFuture = Future.value(drivers);
          _isLoading = false;
        });
      } else {
        throw Exception('搜索失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error searching drivers by ID card: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  /// 按驾驶证号搜索司机信息
  Future<void> _searchDriversByDriverLicenseNumber(String query) async {
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
        Uri.parse(
            'http://localhost:8081/api/drivers/driverLicenseNumber/$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final drivers = _parseDriverResult(data);
        setState(() {
          _driversFuture = Future.value(drivers);
          _isLoading = false;
        });
      } else {
        throw Exception('搜索失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error searching drivers by license: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  /// 创建司机信息
  Future<void> _createDriver(DriverInformation driver) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      driver.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/drivers?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(driver.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建司机成功！')),
        );
        _loadDrivers(); // 刷新列表
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

  /// 更新司机信息
  Future<void> _updateDriver(int driverId, DriverInformation driver) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      driver.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/drivers/$driverId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(driver.toJson()),
      );

      if (response.statusCode == 200) {
        // 200 OK
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新司机成功！')),
        );
        _loadDrivers(); // 刷新列表
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

  /// 删除司机信息
  Future<void> _deleteDriver(int driverId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/drivers/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除司机成功！')),
        );
        _loadDrivers(); // 刷新列表
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

  List<DriverInformation> _parseDriverResult(dynamic result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) =>
              DriverInformation.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [DriverInformation.fromJson(result)];
    }
    return [];
  }

  void _goToDetailPage(DriverInformation driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDetailPage(driver: driver),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadDrivers(); // 详情页更新后刷新列表
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

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('司机信息列表'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'name') {
                    _searchDriversByName(_nameController.text.trim());
                  } else if (value == 'idCard') {
                    _searchDriversByIdCardNumber(
                        _idCardNumberController.text.trim());
                  } else if (value == 'license') {
                    _searchDriversByDriverLicenseNumber(
                        _driverLicenseNumberController.text.trim());
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('按姓名搜索'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'idCard',
                    child: Text('按身份证号搜索'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'license',
                    child: Text('按驾驶证号搜索'),
                  ),
                ],
                icon: Icon(
                  Icons.filter_list,
                  color: isLight ? Colors.white : Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddDriverPage()),
                  ).then((value) {
                    if (value == true && mounted) {
                      _loadDrivers();
                    }
                  });
                },
                tooltip: '添加新司机',
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
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '姓名',
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
                        style: TextStyle(
                          color: isLight ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _searchDriversByName(_nameController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idCardNumberController,
                        decoration: InputDecoration(
                          labelText: '身份证号',
                          prefixIcon: const Icon(Icons.card_membership),
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
                        style: TextStyle(
                          color: isLight ? Colors.black : Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByIdCardNumber(
                          _idCardNumberController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _driverLicenseNumberController,
                        decoration: InputDecoration(
                          labelText: '驾驶证号',
                          prefixIcon: const Icon(Icons.drive_eta),
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
                        style: TextStyle(
                          color: isLight ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByDriverLicenseNumber(
                          _driverLicenseNumberController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (_errorMessage.isNotEmpty)
                  Expanded(child: Center(child: Text(_errorMessage)))
                else
                  Expanded(
                    child: FutureBuilder<List<DriverInformation>>(
                      future: _driversFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '加载司机信息失败: ${snapshot.error}',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无司机信息',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else {
                          final drivers = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadDrivers,
                            // 直接返回 Future<List<DriverInformation>>
                            child: ListView.builder(
                              itemCount: drivers.length,
                              itemBuilder: (context, index) {
                                final driver = drivers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 16.0,
                                  ),
                                  elevation: 4,
                                  color:
                                      isLight ? Colors.white : Colors.grey[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '司机姓名: ${driver.name ?? "未知"}',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '驾驶证号: ${driver.driverLicenseNumber ?? ""}\n'
                                      '联系电话: ${driver.contactNumber ?? ""}',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black54
                                            : Colors.white70,
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final did = driver.driverId;
                                        if (did != null) {
                                          if (value == 'edit') {
                                            _goToDetailPage(driver);
                                          } else if (value == 'delete') {
                                            _deleteDriver(did);
                                          }
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
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    onTap: () => _goToDetailPage(driver),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 添加司机信息页面
class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false; // 添加 _isAdmin
  String _errorMessage = ''; // 添加 _errorMessage

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      } else {
        setState(() {
          _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isAdmin) {
        throw Exception('权限不足：仅管理员可创建司机信息');
      }

      final driver = DriverInformation(
        driverId: null,
        // 后端自动生成，不需要前端指定
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: null,
        birthdate: null,
        firstLicenseDate: null,
        allowedVehicleType: null,
        issueDate: null,
        expiryDate: null,
        idempotencyKey: generateIdempotencyKey(), // 设置幂等键
      );

      await _createDriver(driver);

      if (!mounted) return;
      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      _showErrorSnackBar('创建司机失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDriver(DriverInformation driver) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/drivers?idempotencyKey=${driver.idempotencyKey}'), // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(driver.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建司机成功！')),
        );
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
        title: const Text('添加新司机'),
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '姓名',
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
                      controller: _driverLicenseNumberController,
                      decoration: InputDecoration(
                        labelText: '驾驶证号',
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
                      onPressed: _submitDriver,
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

/// 编辑司机信息页面
class EditDriverPage extends StatefulWidget {
  final DriverInformation driver;

  const EditDriverPage({super.key, required this.driver});

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false; // 添加 _isAdmin
  String _errorMessage = ''; // 添加 _errorMessage

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _checkUserRole(); // 检查用户角色
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text =
        widget.driver.driverLicenseNumber ?? '';
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      } else {
        setState(() {
          _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isAdmin) {
        throw Exception('权限不足：仅管理员可编辑司机信息');
      }

      final driver = DriverInformation(
        driverId: widget.driver.driverId,
        // 后端要求 driverId
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: null,
        birthdate: null,
        firstLicenseDate: null,
        allowedVehicleType: null,
        issueDate: null,
        expiryDate: null,
        idempotencyKey: generateIdempotencyKey(), // 设置幂等键
      );

      await _updateDriver(widget.driver.driverId!, driver);

      if (!mounted) return;
      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      _showErrorSnackBar('更新司机失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDriver(int driverId, DriverInformation driver) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/drivers/$driverId?idempotencyKey=${driver.idempotencyKey}'), // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(driver.toJson()),
      );

      if (response.statusCode == 200) {
        // 200 OK
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新司机成功！')),
        );
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
        title: const Text('编辑司机信息'),
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '姓名',
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
                      controller: _driverLicenseNumberController,
                      decoration: InputDecoration(
                        labelText: '驾驶证号',
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
                      onPressed: _submitDriver,
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

/// 司机详细信息页面
class DriverDetailPage extends StatefulWidget {
  final DriverInformation driver;

  const DriverDetailPage({super.key, required this.driver});

  @override
  State<DriverDetailPage> createState() => _DriverDetailPageState();
}

class _DriverDetailPageState extends State<DriverDetailPage> {
  bool _isLoading = false;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = ''; // 添加 _errorMessage
  final UserDashboardController controller =
      Get.find<UserDashboardController>(); // 确保导入正确的控制器

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      } else {
        setState(() {
          _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    final name = widget.driver.name ?? '未知';
    final idCard = widget.driver.idCardNumber ?? '无';
    final contact = widget.driver.contactNumber ?? '无';
    final license = widget.driver.driverLicenseNumber ?? '无';
    final driverId = widget.driver.driverId ?? 0;

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

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('司机详细信息'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              if (_isAdmin) // 仅 ADMIN 显示编辑按钮
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isLight ? Colors.white : Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditDriverPage(driver: widget.driver),
                      ),
                    ).then((value) {
                      if (value == true && mounted) {
                        setState(() {}); // 刷新页面
                      }
                    });
                  },
                  tooltip: '编辑司机信息',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildDetailRow(
                          context, '司机 ID', driverId.toString()), // 显示司机 ID
                      _buildDetailRow(context, '姓名', name),
                      _buildDetailRow(context, '身份证号', idCard),
                      _buildDetailRow(context, '联系电话', contact),
                      _buildDetailRow(context, '驾驶证号', license),
                    ],
                  ),
          ),
        ),
      ),
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
}
