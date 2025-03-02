import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// 扣分信息管理页面
class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  late DeductionInformationControllerApi deductionApi;
  late Future<List<DeductionInformation>> _deductionsFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>(); // 确保导入正确的控制器
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';
  final TextEditingController _driverLicenseController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    deductionApi = DeductionInformationControllerApi();
    _checkUserRole(); // 检查用户角色并加载扣分记录
  }

  @override
  void dispose() {
    _driverLicenseController.dispose();
    _handlerController.dispose();
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
          _loadDeductions(); // 仅管理员加载所有扣分记录
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

  Future<void> _loadDeductions() async {
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
        Uri.parse('http://localhost:8081/api/deductions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final deductions =
            data.map((json) => DeductionInformation.fromJson(json)).toList();
        setState(() {
          _deductionsFuture = Future.value(deductions);
          _isLoading = false;
        });
      } else {
        throw Exception('加载扣分信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载扣分信息失败: $e';
      });
    }
  }

  Future<void> _searchDeductions(
      String type, String? query, DateTimeRange? dateRange) async {
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
      if (type == 'license' && query != null && query.isNotEmpty) {
        uri = Uri.parse(
            'http://localhost:8081/api/deductions/license/$query'); // 按驾驶证号搜索
      } else if (type == 'handler' && query != null && query.isNotEmpty) {
        uri = Uri.parse(
            'http://localhost:8081/api/deductions/handler/$query'); // 按处理人搜索
      } else if (type == 'timeRange' && dateRange != null) {
        uri = Uri.parse(
            'http://localhost:8081/api/deductions/timeRange?startTime=${dateRange.start.toIso8601String()}&endTime=${dateRange.end.toIso8601String()}');
      } else {
        await _loadDeductions();
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
        final deductions = _parseDeductionResult(data);
        setState(() {
          _deductionsFuture = Future.value(deductions);
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

  Future<void> _createDeduction(DeductionInformation deduction) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      deduction.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/deductions?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(deduction.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建扣分记录成功！')),
        );
        _loadDeductions(); // 刷新列表
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

  Future<void> _updateDeduction(
      int deductionId, DeductionInformation deduction) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      deduction.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/deductions/$deductionId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(deduction.toJson()),
      );

      if (response.statusCode == 200) {
        // 200 OK
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新扣分记录成功！')),
        );
        _loadDeductions(); // 刷新列表
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

  Future<void> _deleteDeduction(int deductionId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/deductions/$deductionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除扣分记录成功！')),
        );
        _loadDeductions(); // 刷新列表
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

  List<DeductionInformation> _parseDeductionResult(dynamic result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) =>
              DeductionInformation.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [DeductionInformation.fromJson(result)];
    }
    return [];
  }

  void _goToDetailPage(DeductionInformation deduction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeductionDetailPage(deduction: deduction),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadDeductions(); // 详情页更新后刷新列表
      }
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData(
          primaryColor: Theme.of(context).colorScheme.primary,
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ).copyWith(secondary: Theme.of(context).colorScheme.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateRange = picked;
      });
      _searchDeductions('timeRange', null, picked);
    }
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
            title: const Text('扣分信息管理'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'license') {
                    _searchDeductions(
                        'license', _driverLicenseController.text.trim(), null);
                  } else if (value == 'handler') {
                    _searchDeductions('handler', _handlerController.text.trim(),
                        null); // 按处理人搜索
                  } else if (value == 'timeRange') {
                    _selectDateRange();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'license',
                    child: Text('按驾驶证号搜索'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'handler',
                    child: Text('按处理人搜索'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'timeRange',
                    child: Text('按时间范围搜索'),
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
                        builder: (context) => const AddDeductionPage()),
                  ).then((value) {
                    if (value == true && mounted) {
                      _loadDeductions();
                    }
                  });
                },
                tooltip: '添加新的扣分记录',
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
                        controller: _driverLicenseController,
                        decoration: InputDecoration(
                          labelText: '驾驶证号',
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
                      onPressed: () => _searchDeductions('license',
                          _driverLicenseController.text.trim(), null),
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
                        controller: _handlerController,
                        decoration: InputDecoration(
                          labelText: '处理人',
                          prefixIcon: const Icon(Icons.person),
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
                      onPressed: () => _searchDeductions(
                          'handler', _handlerController.text.trim(), null),
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
                    child: FutureBuilder<List<DeductionInformation>>(
                      future: _deductionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '加载扣分信息失败: ${snapshot.error}',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无扣分记录',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else {
                          final deductions = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadDeductions,
                            // 直接返回 Future<List<DeductionInformation>>
                            child: ListView.builder(
                              itemCount: deductions.length,
                              itemBuilder: (context, index) {
                                final deduction = deductions[index];
                                final points = deduction.deductedPoints ?? 0;
                                final time = deduction.deductionTime ?? '未知';
                                final handler = deduction.handler ?? '未记录';

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
                                      '扣分: $points 分',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '时间: $time\n处理人: $handler',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black54
                                            : Colors.white70,
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final did = deduction.deductionId;
                                        if (did != null) {
                                          if (value == 'edit') {
                                            _goToDetailPage(deduction);
                                          } else if (value == 'delete') {
                                            _deleteDeduction(did);
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
                                    onTap: () => _goToDetailPage(deduction),
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

/// 添加扣分信息页面
class AddDeductionPage extends StatefulWidget {
  const AddDeductionPage({super.key});

  @override
  State<AddDeductionPage> createState() => _AddDeductionPageState();
}

class _AddDeductionPageState extends State<AddDeductionPage> {
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false; // 添加 _isAdmin

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
      }
    }
  }

  @override
  void dispose() {
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitDeduction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deduction = DeductionInformation(
        deductionId: null,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: _dateController.text.trim(),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
        approver: null, // 设置默认值或从 UI 收集
      );

      await _createDeduction(deduction);

      if (!mounted) return;
      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      _showErrorSnackBar('创建扣分记录失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDeduction(DeductionInformation deduction) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      deduction.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/deductions?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(deduction.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建扣分记录成功！')),
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
            '权限不足：仅管理员可访问此页面',
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加扣分信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: _buildDeductionForm(context, isLight),
              ),
      ),
    );
  }

  Widget _buildDeductionForm(BuildContext context, bool isLight) {
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon: const Icon(Icons.drive_eta),
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
          controller: _deductedPointsController,
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: const Icon(Icons.score),
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
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          decoration: InputDecoration(
            labelText: '处理人',
            prefixIcon: const Icon(Icons.person),
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
          controller: _remarksController,
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: const Icon(Icons.notes),
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
          controller: _dateController,
          decoration: InputDecoration(
            labelText: '扣分时间',
            prefixIcon: const Icon(Icons.date_range),
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
          readOnly: true,
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
          ),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode()); // 关闭键盘
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
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
            if (pickedDate != null && mounted) {
              setState(() {
                _dateController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              });
            }
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDeduction,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
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
            foregroundColor: isLight ? Colors.black87 : Colors.white,
          ),
          child: const Text('返回上一级'),
        ),
      ],
    );
  }
}

/// 编辑扣分信息页面
class EditDeductionPage extends StatefulWidget {
  final DeductionInformation deduction;

  const EditDeductionPage({super.key, required this.deduction});

  @override
  State<EditDeductionPage> createState() => _EditDeductionPageState();
}

class _EditDeductionPageState extends State<EditDeductionPage> {
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false; // 添加 _isAdmin

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _checkUserRole(); // 检查用户角色
  }

  void _initializeFields() {
    _driverLicenseNumberController.text =
        widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text =
        (widget.deduction.deductedPoints ?? 0).toString();
    _handlerController.text = widget.deduction.handler ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text = widget.deduction.deductionTime ?? '';
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
      }
    }
  }

  @override
  void dispose() {
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitDeduction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: _dateController.text.trim(),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
        approver: null, // 设置默认值或从 UI 收集
      );

      await _updateDeduction(widget.deduction.deductionId!, deduction);

      if (!mounted) return;
      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      _showErrorSnackBar('更新扣分记录失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDeduction(
      int deductionId, DeductionInformation deduction) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      deduction.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/deductions/$deductionId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(deduction.toJson()),
      );

      if (response.statusCode == 200) {
        // 200 OK
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新扣分记录成功！')),
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
            '权限不足：仅管理员可访问此页面',
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑扣分信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: _buildDeductionForm(context, isLight),
              ),
      ),
    );
  }

  Widget _buildDeductionForm(BuildContext context, bool isLight) {
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon: const Icon(Icons.drive_eta),
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
          controller: _deductedPointsController,
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: const Icon(Icons.score),
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
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          decoration: InputDecoration(
            labelText: '处理人',
            prefixIcon: const Icon(Icons.person),
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
          controller: _remarksController,
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: const Icon(Icons.notes),
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
          controller: _dateController,
          decoration: InputDecoration(
            labelText: '扣分时间',
            prefixIcon: const Icon(Icons.date_range),
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
          readOnly: true,
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
          ),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode()); // 关闭键盘
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
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
            if (pickedDate != null && mounted) {
              setState(() {
                _dateController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              });
            }
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDeduction,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
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
            foregroundColor: isLight ? Colors.black87 : Colors.white,
          ),
          child: const Text('返回上一级'),
        ),
      ],
    );
  }
}

/// 扣分详情页面
class DeductionDetailPage extends StatefulWidget {
  final DeductionInformation deduction;

  const DeductionDetailPage({super.key, required this.deduction});

  @override
  State<DeductionDetailPage> createState() => _DeductionDetailPageState();
}

class _DeductionDetailPageState extends State<DeductionDetailPage> {
  bool _isLoading = false;
  bool _isAdmin = false; // 确保是管理员
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.deduction.remarks ?? '';
    _checkUserRole();
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
      }
    }
  }

  Future<void> _updateDeduction(
      int deductionId, DeductionInformation deduction) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      deduction.idempotencyKey = idempotencyKey; // 设置幂等键
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/deductions/$deductionId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(deduction.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('更新扣分记录成功！')),
        );
        setState(() {
          widget.deduction.remarks = _remarksController.text.trim();
        });
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
                Text('更新失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDeduction(int deductionId) async {
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
        Uri.parse('http://localhost:8081/api/deductions/$deductionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('扣分记录删除成功！')),
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

    final points = widget.deduction.deductedPoints ?? 0;
    final time = widget.deduction.deductionTime ?? '未知';
    final handler = widget.deduction.handler ?? '未记录';

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            '权限不足：仅管理员可访问此页面',
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
            title: const Text('扣分详情'),
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
                            EditDeductionPage(deduction: widget.deduction),
                      ),
                    ).then((value) {
                      if (value == true && mounted) {
                        _loadDeductions(); // 编辑后刷新列表
                      }
                    });
                  },
                  tooltip: '编辑扣分',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildDetailRow(context, '扣分 ID',
                          widget.deduction.deductionId?.toString() ?? '无'),
                      _buildDetailRow(context, '扣分分数', '$points 分'),
                      _buildDetailRow(context, '扣分时间', time),
                      _buildDetailRow(context, '处理人', handler),
                      ListTile(
                        title: Text('备注',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: TextField(
                          controller: _remarksController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isLight ? Colors.grey : Colors.grey[500]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isLight ? Colors.blue : Colors.blueGrey,
                              ),
                            ),
                          ),
                          maxLines: 3,
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                          onSubmitted: (value) => _updateDeduction(
                              widget.deduction.deductionId ?? 0,
                              widget.deduction.copyWith(
                                  remarks: value.trim(),
                                  handler: widget.deduction.handler,
                                  deductedPoints:
                                      widget.deduction.deductedPoints,
                                  deductionTime: widget.deduction.deductionTime,
                                  driverLicenseNumber:
                                      widget.deduction.driverLicenseNumber)),
                        ),
                      ),
                      if (_isAdmin) // 仅 ADMIN 可以删除
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _deleteDeduction(
                                  widget.deduction.deductionId ?? 0),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: const Text('删除扣分'),
                            ),
                          ],
                        ),
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
