import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// FineList 页面：管理员才能访问
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
  bool _isAdmin = false;
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

  /// 解析 JWT 的方法
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT format');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT Decode Error: $e');
      return {};
    }
  }

  /// 根据 JWT 判断是否为管理员
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
    final decodedJwt = _decodeJwt(jwtToken);
    final roles = decodedJwt['roles']?.toString().split(',') ?? [];
    setState(() {
      _isAdmin = roles.contains('ADMIN');
      if (_isAdmin) {
        _loadFines(); // 管理员加载所有罚款
      } else {
        _errorMessage = '权限不足：仅管理员可访问此页面';
        _isLoading = false;
      }
    });
  }

  Future<void> _loadFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

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
      if (jwtToken == null) throw Exception('No JWT token found');

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
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('创建罚款成功！')));
        _loadFines();
      } else {
        throw Exception('创建失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('创建失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    }
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
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
        _loadFines();
      } else {
        throw Exception('更新失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('更新失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('删除罚款成功！')));
        _loadFines();
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('删除失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    }
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
      MaterialPageRoute(builder: (context) => FineDetailPage(fine: fine)),
    ).then((value) {
      if (value == true && mounted) _loadFines();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
          primaryColor: Theme.of(context).colorScheme.primary,
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
    final theme = Theme.of(context);

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage, style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('罚款信息列表',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
                  MaterialPageRoute(
                      builder: (context) => const AddFinePage())).then((value) {
                if (value == true && mounted) _loadFines();
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
                          borderRadius: BorderRadius.circular(8.0)),
                      labelStyle: theme.textTheme.bodyMedium,
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary)),
                    ),
                    onChanged: (value) => _searchFines('payee', value, null),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _searchFines('payee', _payeeController.text.trim(), null),
                  style: theme.elevatedButtonTheme.style,
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(
                  child: Center(
                      child: Text(_errorMessage,
                          style: theme.textTheme.bodyLarge)))
            else
              Expanded(
                child: FutureBuilder<List<FineInformation>>(
                  future: _finesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('加载罚款信息失败: ${snapshot.error}',
                              style: theme.textTheme.bodyLarge));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text('没有找到罚款信息',
                              style: theme.textTheme.bodyLarge));
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
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            child: ListTile(
                              title: Text('罚款金额: $amount 元',
                                  style: theme.textTheme.bodyLarge),
                              subtitle: Text(
                                '缴款人: $payee\n罚款时间: $time\n状态: $status',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7)),
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
                                        value: 'approve', child: Text('批准')),
                                  if (status == 'Pending')
                                    const PopupMenuItem<String>(
                                        value: 'reject', child: Text('拒绝')),
                                  const PopupMenuItem<String>(
                                      value: 'delete', child: Text('删除')),
                                ],
                                icon: Icon(Icons.more_vert,
                                    color: theme.colorScheme.onSurface),
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

/// 添加罚款页面
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
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final fine = FineInformation(
        fineId: null,
        offenseId: 0,
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bank: _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        fineTime: _dateController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
        status: 'Pending',
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
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('创建罚款成功！')));
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('创建失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('创建罚款失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加新罚款',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: _buildFineInfoForm(context)),
      ),
    );
  }

  Widget _buildFineInfoForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: _plateNumberController,
          decoration: InputDecoration(
            labelText: '车牌号',
            prefixIcon: const Icon(Icons.local_car_wash),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fineAmountController,
          decoration: InputDecoration(
            labelText: '罚款金额 (\$)',
            prefixIcon: const Icon(Icons.money),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _payeeController,
          decoration: InputDecoration(
            labelText: '收款人',
            prefixIcon: const Icon(Icons.person),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: '银行账号',
            prefixIcon: const Icon(Icons.account_balance),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bankController,
          decoration: InputDecoration(
            labelText: '银行名称',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _receiptNumberController,
          decoration: InputDecoration(
            labelText: '收据编号',
            prefixIcon: const Icon(Icons.receipt),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remarksController,
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: const Icon(Icons.notes),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: '罚款日期',
            prefixIcon: const Icon(Icons.date_range),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          readOnly: true,
          style: theme.textTheme.bodyMedium,
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme,
                  primaryColor: theme.colorScheme.primary,
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
          style: theme.elevatedButtonTheme.style,
          child: const Text('提交'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: theme.elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all(
                theme.colorScheme.onSurface.withOpacity(0.2)),
            foregroundColor:
                MaterialStateProperty.all(theme.colorScheme.onSurface),
          ),
          child: const Text('返回上一级'),
        ),
      ],
    );
  }
}

/// 罚款详情页面
class FineDetailPage extends StatefulWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  State<FineDetailPage> createState() => _FineDetailPageState();
}

class _FineDetailPageState extends State<FineDetailPage> {
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.fine.remarks ?? '';
    _checkUserRole();
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT format');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT Decode Error: $e');
      return {};
    }
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
    final decodedJwt = _decodeJwt(jwtToken);
    final roles = decodedJwt['roles']?.toString().split(',') ?? [];
    setState(() {
      _isAdmin = roles.contains('ADMIN');
      _isLoading = false;
    });
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
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
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('更新失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('更新状态失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }
      setState(() => _isLoading = true);
      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/fines/$fineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 204) {
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('罚款删除成功！')));
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('删除失败: $e',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = widget.fine.fineAmount ?? 0;
    final payee = widget.fine.payee ?? '';
    final time = widget.fine.fineTime ?? '';
    final receipt = widget.fine.receiptNumber ?? '';
    final status = widget.fine.status ?? 'Pending';

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
          body: Center(
              child: Text(_errorMessage, style: theme.textTheme.bodyLarge)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('罚款详细信息',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_isAdmin)
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
                      value: 'approve', child: Text('批准')),
                if (status == 'Pending')
                  const PopupMenuItem<String>(
                      value: 'reject', child: Text('拒绝')),
                const PopupMenuItem<String>(value: 'delete', child: Text('删除')),
              ],
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
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
                    title: Text('备注', style: theme.textTheme.bodyLarge),
                    subtitle: TextField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        labelStyle: theme.textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary)),
                      ),
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium,
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
