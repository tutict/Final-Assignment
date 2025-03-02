import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  var uuid = const Uuid();
  return uuid.v4();
}

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage> {
  late FineInformationControllerApi fineApi;
  late Future<List<FineInformation>> _finesFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = false;
  bool _isUser = true; // 假设为普通用户（USER 角色）
  String _errorMessage = '';
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

  @override
  void initState() {
    super.initState();
    fineApi = FineInformationControllerApi();
    _checkUserRole(); // 检查用户角色
  }

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

  Future<void> _checkUserRole() async {
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
        throw Exception(
            '验证失败：${roleResponse.statusCode} - ${roleResponse.body}');
      }

      await _loadUserFines(); // 仅加载当前用户的罚款
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _loadUserFines() async {
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

      // 假设后端通过 JWT 自动过滤当前用户的罚款
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
        throw Exception('加载用户罚款失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载罚款信息失败: $e';
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearForm() {
    _plateNumberController.clear();
    _fineAmountController.clear();
    _payeeController.clear();
    _accountNumberController.clear();
    _bankController.clear();
    _receiptNumberController.clear();
    _remarksController.clear();
    _dateController.clear();
  }

  /// 提交罚款信息（用户提交，状态为 Pending）
  Future<void> _submitFineInfo() async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final String idempotencyKey = generateIdempotencyKey();

      final fineInfo = FineInformation(
        fineId: null,
        // 由后端生成
        offenseId: 0,
        // 示例，需根据实际业务从前端获取或从上下文推导（例如关联车辆或违法行为）
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bank: _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        fineTime: _dateController.text.trim(),
        idempotencyKey: idempotencyKey,
        status: 'Pending', // 初始状态为待审批
      );

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/fines?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(fineInfo.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created 表示成功创建请求
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('罚款信息已提交，等待管理员审批')),
        );
        _clearForm();
      } else {
        throw Exception(
            '提交失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('提交罚款信息失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        title: const Text('交通违法罚款记录'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  // 罚款记录输入表单（仅 USER 可提交）
                  _buildFineInfoForm(context, isLight),
                  const SizedBox(height: 16),
                  // 罚款记录列表（只显示当前用户的记录）
                  Expanded(
                    child: FutureBuilder<List<FineInformation>>(
                      future: _finesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '加载罚款信息失败: ${snapshot.error}',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无罚款记录',
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
                              final record = fines[index];
                              final amount = record.fineAmount ?? 0;
                              final payee = record.payee ?? '';
                              final date = record.fineTime ?? '';
                              final status =
                                  record.status ?? 'Pending'; // 使用 status 字段
                              return Card(
                                elevation: 2,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                color:
                                    isLight ? Colors.white : Colors.grey[800],
                                child: ListTile(
                                  title: Text(
                                    '罚款金额: \$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isLight
                                          ? Colors.black87
                                          : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '缴款人: $payee / 时间: $date\n状态: $status',
                                    style: TextStyle(
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70,
                                    ),
                                  ),
                                  // 用户无法编辑或删除，仅查看
                                  trailing: null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUserFines, // 刷新数据（仅 USER）
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        child: const Icon(Icons.refresh),
        tooltip: '刷新罚款记录',
      ),
    );
  }

  /// 构建罚款信息输入表单
  Widget _buildFineInfoForm(BuildContext context, bool isLight) {
    return SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitFineInfo, // 仅 USER 可以提交
            style: ElevatedButton.styleFrom(
              backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('提交罚款信息'),
          ),
        ],
      ),
    );
  }
}
