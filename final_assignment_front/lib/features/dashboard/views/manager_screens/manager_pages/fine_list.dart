import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 格式化日期的全局方法
String formatDate(String? date) {
  if (date == null || date.isEmpty) return '无';
  try {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
  } catch (e) {
    return date;
  }
}

/// FineList 页面：管理员才能访问
class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListPageState();
}

class _FineListPageState extends State<FineList> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final TextEditingController _payeeController = TextEditingController();
  List<FineInformation> _fineList = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';
  DateTimeRange? _dateRange;
  String _searchType = 'payee'; // 默认搜索类型为缴款人

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _payeeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录以查看罚款信息';
      });
      return;
    }
    await fineApi.initializeWithJwt();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = roleData['roles'] as List<dynamic>;
        setState(() {
          _isAdmin = roles.contains('ADMIN');
          if (_isAdmin) {
            _fetchFines();
          } else {
            _errorMessage = '权限不足：仅管理员可访问此页面';
            _isLoading = false;
          }
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载权限失败: $e';
      });
    }
  }

  Future<void> _fetchFines() async {
    if (!_isAdmin) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final fines = await fineApi.apiFinesGet();
      setState(() {
        _fineList = fines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取罚款信息失败: $e';
      });
    }
  }

  Future<void> _searchFines(String query) async {
    if (!_isAdmin) return;
    if (query.isEmpty && _dateRange == null) {
      await _fetchFines();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _fineList.clear();
    });
    try {
      if (_searchType == 'payee' && query.isNotEmpty) {
        final fines = await fineApi.apiFinesPayeePayeeGet(payee: query);
        setState(() {
          _fineList = fines;
          _isLoading = false;
          if (_fineList.isEmpty) _errorMessage = '未找到缴款人为 $query 的罚款信息';
        });
      } else if (_searchType == 'timeRange' && _dateRange != null) {
        final fines = await fineApi.apiFinesTimeRangeGet(
          startTime: _dateRange!.start.toIso8601String(),
          endTime: _dateRange!.end.toIso8601String(),
        );
        setState(() {
          _fineList = fines;
          _isLoading = false;
          if (_fineList.isEmpty) _errorMessage = '未找到该时间范围内的罚款信息';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
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
    if (picked != null && mounted) {
      setState(() {
        _dateRange = picked;
        _searchType = 'timeRange';
        _payeeController.clear();
      });
      _searchFines('');
    }
  }

  void _createFine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFinePage()),
    ).then((value) {
      if (value == true && mounted) _fetchFines();
    });
  }

  void _goToDetailPage(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FineDetailPage(fine: fine)),
    ).then((value) {
      if (value == true && mounted) _fetchFines();
    });
  }

  Future<void> _deleteFine(int fineId) async {
    try {
      await fineApi.apiFinesFineIdDelete(fineId: fineId);
      _showSnackBar('删除罚款成功！');
      _fetchFines();
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

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _payeeController,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: _searchType == 'payee' ? '搜索缴款人' : '按时间范围搜索（已选择）',
                hintStyle: TextStyle(
                    color: themeData.colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon:
                    Icon(Icons.search, color: themeData.colorScheme.primary),
                suffixIcon:
                    _payeeController.text.isNotEmpty || _dateRange != null
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _payeeController.clear();
                              _dateRange = null;
                              _searchType = 'payee';
                              _fetchFines();
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
              ),
              onSubmitted: (value) => _searchFines(value),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _searchType,
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
                _payeeController.clear();
                _dateRange = null;
                _fetchFines();
              });
            },
            items: <String>['payee', 'timeRange']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value == 'payee' ? '按缴款人' : '按时间范围',
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                ),
              );
            }).toList(),
            dropdownColor: themeData.colorScheme.surfaceContainer,
            icon: Icon(Icons.arrow_drop_down,
                color: themeData.colorScheme.primary),
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
              Text(_errorMessage,
                  style: themeData.textTheme.titleMedium?.copyWith(
                    color: themeData.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  )),
              if (_errorMessage.contains('登录'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.colorScheme.primary,
                      foregroundColor: themeData.colorScheme.onPrimary,
                    ),
                    child: const Text('前往登录'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('罚款信息列表',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            )),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: '按时间范围搜索',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createFine,
            tooltip: '添加新罚款',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFines,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchField(themeData),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                themeData.colorScheme.primary)))
                    : _fineList.isEmpty
                        ? Center(
                            child: Text('暂无罚款信息',
                                style:
                                    themeData.textTheme.titleMedium?.copyWith(
                                  color: themeData.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                )))
                        : ListView.builder(
                            itemCount: _fineList.length,
                            itemBuilder: (context, index) {
                              final fine = _fineList[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 3,
                                color: themeData.colorScheme.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  title: Text(
                                    '罚款金额: ${fine.fineAmount ?? 0} 元',
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                      color: themeData.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('缴款人: ${fine.payee ?? '未知'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          )),
                                      Text('时间: ${formatDate(fine.fineTime)}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          )),
                                      Text('状态: ${fine.status ?? 'Pending'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          )),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'approve' &&
                                          fine.status == 'Pending') {
                                        _updateFineStatus(
                                            fine.fineId!, 'Approved');
                                      } else if (value == 'reject' &&
                                          fine.status == 'Pending') {
                                        _updateFineStatus(
                                            fine.fineId!, 'Rejected');
                                      } else if (value == 'delete') {
                                        _deleteFine(fine.fineId!);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (fine.status == 'Pending')
                                        const PopupMenuItem<String>(
                                            value: 'approve',
                                            child: Text('批准')),
                                      if (fine.status == 'Pending')
                                        const PopupMenuItem<String>(
                                            value: 'reject', child: Text('拒绝')),
                                      const PopupMenuItem<String>(
                                          value: 'delete', child: Text('删除')),
                                    ],
                                    icon: Icon(Icons.more_vert,
                                        color: themeData
                                            .colorScheme.onSurfaceVariant),
                                  ),
                                  onTap: () => _goToDetailPage(fine),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFine,
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '添加新罚款',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    try {
      final idempotencyKey = generateIdempotencyKey();
      await fineApi.apiFinesFineIdPut(
        fineId: fineId,
        fineInformation: FineInformation(
          status: status,
          fineTime: DateTime.now().toIso8601String(),
          idempotencyKey: idempotencyKey,
        ),
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('罚款记录已${status == 'Approved' ? '批准' : '拒绝'}');
      _fetchFines();
    } catch (e) {
      _showSnackBar('更新失败: $e', isError: true);
    }
  }
}

/// 添加罚款页面
class AddFinePage extends StatefulWidget {
  const AddFinePage({super.key});

  @override
  State<AddFinePage> createState() => _AddFinePageState();
}

class _AddFinePageState extends State<AddFinePage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    fineApi.initializeWithJwt();
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

  Future<void> _submitFine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final fine = FineInformation(
        fineId: null,
        offenseId: 0,
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bank: _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        fineTime: _dateController.text.isNotEmpty
            ? DateTime.parse(_dateController.text.trim()).toIso8601String()
            : null,
        status: 'Pending',
        idempotencyKey: idempotencyKey,
      );

      await fineApi.apiFinesPost(
        fineInformation: fine,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建罚款成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建罚款失败: $e', isError: true);
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
        _dateController.text = formatDate(pickedDate.toIso8601String());
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
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
        title: Text(
          '添加新罚款',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
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
                      Card(
                        elevation: 3,
                        color: themeData.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                  '车牌号', _plateNumberController, themeData),
                              _buildTextField(
                                  '罚款金额 (元)', _fineAmountController, themeData,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  required: true),
                              _buildTextField(
                                  '缴款人', _payeeController, themeData,
                                  required: true),
                              _buildTextField(
                                  '银行账号', _accountNumberController, themeData),
                              _buildTextField(
                                  '银行名称', _bankController, themeData),
                              _buildTextField(
                                  '收据编号', _receiptNumberController, themeData),
                              _buildTextField(
                                  '备注', _remarksController, themeData),
                              _buildTextField(
                                  '罚款日期', _dateController, themeData,
                                  readOnly: true, onTap: _pickDate),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitFine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 20.0),
                          textStyle: themeData.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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

/// 罚款详情页面
// ... (previous imports and code remain unchanged)

class FineDetailPage extends StatefulWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  State<FineDetailPage> createState() => _FineDetailPageState();
}

class _FineDetailPageState extends State<FineDetailPage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final TextEditingController _remarksController = TextEditingController();

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.fine.remarks ?? '';
    _initialize();
  }

  Future<void> _initialize() async {
    await fineApi.initializeWithJwt();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
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
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = roleData['roles'] as List<dynamic>;
        setState(() {
          _isAdmin = roles.contains('ADMIN');
          _isLoading = false;
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载权限失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      await fineApi.apiFinesFineIdPut(
        fineId: fineId,
        fineInformation: FineInformation(
          status: status,
          fineTime: DateTime.now().toIso8601String(),
          remarks: _remarksController.text.trim(),
          idempotencyKey: idempotencyKey,
        ),
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('罚款记录已${status == 'Approved' ? '批准' : '拒绝'}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新状态失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    setState(() => _isLoading = true);
    try {
      await fineApi.apiFinesFineIdDelete(fineId: fineId);
      _showSnackBar('罚款删除成功！');
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
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
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
          child: Text(
            _errorMessage,
            style: themeData.textTheme.titleMedium?.copyWith(
              color: themeData.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '罚款详细信息',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: _isAdmin
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'approve' && widget.fine.status == 'Pending') {
                      _updateFineStatus(widget.fine.fineId ?? 0, 'Approved');
                    } else if (value == 'reject' &&
                        widget.fine.status == 'Pending') {
                      _updateFineStatus(widget.fine.fineId ?? 0, 'Rejected');
                    } else if (value == 'delete') {
                      _deleteFine(widget.fine.fineId ?? 0);
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.fine.status == 'Pending')
                      const PopupMenuItem<String>(
                          value: 'approve', child: Text('批准')),
                    if (widget.fine.status == 'Pending')
                      const PopupMenuItem<String>(
                          value: 'reject', child: Text('拒绝')),
                    const PopupMenuItem<String>(
                        value: 'delete', child: Text('删除')),
                  ],
                  icon: Icon(Icons.more_vert,
                      color: themeData.colorScheme.onSurfaceVariant),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('罚款金额',
                            '${widget.fine.fineAmount ?? 0} 元', themeData),
                        _buildDetailRow(
                            '缴款人', widget.fine.payee ?? '未知', themeData),
                        _buildDetailRow('罚款时间',
                            formatDate(widget.fine.fineTime), themeData),
                        // 修正车牌号字段：当前 FineInformation 无 plateNumber，使用占位符
                        _buildDetailRow('车牌号', '未知', themeData), // 临时修正，见下方说明
                        _buildDetailRow('银行账号',
                            widget.fine.accountNumber ?? '未知', themeData),
                        _buildDetailRow(
                            '银行名称', widget.fine.bank ?? '未知', themeData),
                        _buildDetailRow('收据编号',
                            widget.fine.receiptNumber ?? '未知', themeData),
                        _buildDetailRow(
                            '状态', widget.fine.status ?? 'Pending', themeData),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: TextFormField(
                            controller: _remarksController,
                            style: TextStyle(
                                color: themeData.colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: '备注',
                              labelStyle: TextStyle(
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: themeData.colorScheme.outline
                                          .withOpacity(0.3))),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: themeData.colorScheme.primary,
                                      width: 1.5)),
                              filled: true,
                              fillColor:
                                  themeData.colorScheme.surfaceContainerLowest,
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
