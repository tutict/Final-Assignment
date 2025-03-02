import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListPageState();
}

class _FineListPageState extends State<FineList> {
  late FineInformationControllerApi fineApi;
  late Future<List<FineInformation>> _finesFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  bool _isAdmin = false; // 假设从状态管理或 SharedPreferences 获取
  String _errorMessage = '';
  final TextEditingController _payeeController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    fineApi = FineInformationControllerApi();
    _checkUserRole(); // 检查用户角色并加载罚款
  }

  @override
  void dispose() {
    _payeeController.dispose();
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
          _loadFines(); // 仅管理员加载所有罚款
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

  Future<void> _loadFines() async {
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
        Uri.parse('http://localhost:8081/api/fines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fines =
            data.map((json) => FineInformation.fromJson(json)).toList();
        setState(() {
          _finesFuture = Future.value(fines);
          _isLoading = false;
        });
      } else {
        throw Exception('加载罚款信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载罚款信息失败: $e';
      });
    }
  }

  Future<void> _searchFines(
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
      if (type == 'payee' && query != null && query.isNotEmpty) {
        uri = Uri.parse('http://localhost:8081/api/fines/payee/$query');
      } else if (type == 'timeRange' && dateRange != null) {
        uri = Uri.parse(
            'http://localhost:8081/api/fines/time-range?startTime=${dateRange.start.toIso8601String()}&endTime=${dateRange.end.toIso8601String()}');
      } else {
        await _loadFines();
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
        final fines = _parseFineResult(data);
        setState(() {
          _finesFuture = Future.value(fines);
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

  Future<void> _createFine(FineInformation fine) async {
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
            'http://localhost:8081/api/fines?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(fine.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建罚款成功！')),
        );
        _loadFines(); // 刷新列表
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

  Future<void> _updateFineStatus(int fineId, String status) async {
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

      final response = await http.put(
        Uri.parse('http://localhost:8081/api/fines/$fineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('罚款记录已${status == 'Approved' ? '批准' : '拒绝'}')),
        );
        _loadFines(); // 刷新列表
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

  Future<void> _deleteFine(int fineId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/fines/$fineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除罚款成功！')),
        );
        _loadFines(); // 刷新列表
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  List<FineInformation> _parseFineResult(dynamic result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) => FineInformation.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [FineInformation.fromJson(result)];
    }
    return [];
  }

  void _goToDetailPage(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FineDetailPage(fine: fine),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadFines(); // 详情页更新后刷新列表
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
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
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _searchFines('timeRange', null, _dateRange);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('罚款信息列表'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _selectDateRange,
            tooltip: '按时间范围搜索',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFinePage()),
              ).then((value) {
                if (value == true && mounted) {
                  _loadFines();
                }
              });
            },
            tooltip: '添加新罚款',
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
                    controller: _payeeController,
                    decoration: InputDecoration(
                      labelText: '按缴款人搜索',
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
                    onChanged: (value) => _searchFines('payee', value, null),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _searchFines('payee', _payeeController.text.trim(), null),
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
                child: FutureBuilder<List<FineInformation>>(
                  future: _finesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '加载罚款信息失败: ${snapshot.error}',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          '没有找到罚款信息',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      );
                    } else {
                      final fines = snapshot.data!;
                      return ListView.builder(
                        itemCount: fines.length,
                        itemBuilder: (context, index) {
                          final fine = fines[index];
                          final payee = fine.payee ?? '';
                          final amount = fine.fineAmount ?? 0;
                          final time = fine.fineTime ?? '';
                          final status = fine.status ?? 'Pending';
                          final fid = fine.fineId ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                '罚款金额: $amount 元',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '缴款人: $payee\n罚款时间: $time\n状态: $status',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'approve' &&
                                      status == 'Pending') {
                                    _updateFineStatus(fid, 'Approved');
                                  } else if (value == 'reject' &&
                                      status == 'Pending') {
                                    _updateFineStatus(fid, 'Rejected');
                                  } else if (value == 'delete') {
                                    _deleteFine(fid);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (status == 'Pending')
                                    const PopupMenuItem<String>(
                                      value: 'approve',
                                      child: Text('批准'),
                                    ),
                                  if (status == 'Pending')
                                    const PopupMenuItem<String>(
                                      value: 'reject',
                                      child: Text('拒绝'),
                                    ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('删除'),
                                  ),
                                ],
                                icon: Icon(
                                  Icons.more_vert,
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              onTap: () => _goToDetailPage(fine),
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

class AddFinePage extends StatefulWidget {
  const AddFinePage({super.key});

  @override
  State<AddFinePage> createState() => _AddFinePageState();
}

class _AddFinePageState extends State<AddFinePage> {
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _fineAmountController = TextEditingController();
  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _receiptNumberController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateNumberController.dispose();
    _fineAmountController.dispose();
    _payeeController.dispose();
    _accountNumberController.dispose();
    _bankController.dispose();
    _receiptNumberController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitFine() async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final fine = FineInformation(
        fineId: null,
        offenseId: 0,
        // 示例，需根据实际业务从前端获取或从上下文推导
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bank: _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        fineTime: _dateController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
        status: 'Pending', // 初始状态为待审批
      );

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/fines?idempotencyKey=${generateIdempotencyKey()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(fine.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('创建罚款成功！')),
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
                Text('创建罚款失败: $e', style: const TextStyle(color: Colors.red))),
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
        title: const Text('添加新罚款'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: _buildFineInfoForm(context, isLight),
              ),
      ),
    );
  }

  Widget _buildFineInfoForm(BuildContext context, bool isLight) {
    return Column(
      children: [
        TextField(
          controller: _plateNumberController,
          decoration: InputDecoration(
            labelText: '车牌号',
            prefixIcon: const Icon(Icons.local_car_wash),
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
          controller: _fineAmountController,
          decoration: InputDecoration(
            labelText: '罚款金额 (\$)',
            prefixIcon: const Icon(Icons.money),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _payeeController,
          decoration: InputDecoration(
            labelText: '收款人',
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
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: '银行账号',
            prefixIcon: const Icon(Icons.account_balance),
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
          controller: _bankController,
          decoration: InputDecoration(
            labelText: '银行名称',
            prefixIcon: const Icon(Icons.account_balance_wallet),
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
          controller: _receiptNumberController,
          decoration: InputDecoration(
            labelText: '收据编号',
            prefixIcon: const Icon(Icons.receipt),
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
            labelText: '罚款日期',
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
            if (pickedDate != null) {
              setState(() {
                _dateController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              });
            }
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitFine,
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

class FineDetailPage extends StatefulWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  State<FineDetailPage> createState() => _FineDetailPageState();
}

class _FineDetailPageState extends State<FineDetailPage> {
  bool _isLoading = false;
  bool _isAdmin = false; // 管理员权限标识
  String _errorMessage = ''; // 错误消息
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.fine.remarks ?? '';
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

  Future<void> _updateFineStatus(int fineId, String status) async {
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

      final response = await http.put(
        Uri.parse('http://localhost:8081/api/fines/$fineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          'remarks': _remarksController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('罚款记录已${status == 'Approved' ? '批准' : '拒绝'}')),
        );
        setState(() {
          widget.fine.status = status;
          widget.fine.remarks = _remarksController.text.trim();
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
                Text('更新状态失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFine(int fineId) async {
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
        Uri.parse('http://localhost:8081/api/fines/$fineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('罚款删除成功！')),
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

    final amount = widget.fine.fineAmount ?? 0;
    final payee = widget.fine.payee ?? '';
    final time = widget.fine.fineTime ?? '';
    final receipt = widget.fine.receiptNumber ?? '';
    final status = widget.fine.status ?? 'Pending';

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
        title: const Text('罚款详细信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          if (_isAdmin) // 仅 ADMIN 显示操作按钮
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'approve' && status == 'Pending') {
                  _updateFineStatus(widget.fine.fineId ?? 0, 'Approved');
                } else if (value == 'reject' && status == 'Pending') {
                  _updateFineStatus(widget.fine.fineId ?? 0, 'Rejected');
                } else if (value == 'delete') {
                  _deleteFine(widget.fine.fineId ?? 0);
                }
              },
              itemBuilder: (context) => [
                if (status == 'Pending')
                  const PopupMenuItem<String>(
                    value: 'approve',
                    child: Text('批准'),
                  ),
                if (status == 'Pending')
                  const PopupMenuItem<String>(
                    value: 'reject',
                    child: Text('拒绝'),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(context, '罚款金额', '$amount 元'),
                  _buildDetailRow(context, '缴款人', payee),
                  _buildDetailRow(context, '罚款时间', time),
                  _buildDetailRow(context, '收据号', receipt),
                  _buildDetailRow(context, '状态', status),
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
                            color: isLight ? Colors.grey : Colors.grey[500]!,
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
                      onSubmitted: (value) =>
                          _updateFineStatus(widget.fine.fineId ?? 0, status),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
