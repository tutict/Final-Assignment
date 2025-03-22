import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // For JWT decoding
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:get/get.dart';

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
    return date ?? '无';
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
  late ScrollController _scrollController;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initialize();
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _scrollController.dispose();
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
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '未找到JWT token，请重新登录';
        });
        return;
      }

      // Decode the JWT token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
      debugPrint('Decoded JWT: $decodedToken');

      // Extract roles and handle String or List cases
      final rolesData = decodedToken['roles'];
      List<dynamic> roles;
      if (rolesData is String) {
        roles = [rolesData]; // Convert String to single-element List
      } else {
        roles = rolesData as List<dynamic>? ?? []; // Handle List or null
      }
      debugPrint('Processed Roles: $roles');

      setState(() {
        _isAdmin = roles.contains('ADMIN');
        if (_isAdmin) {
          _fetchFines();
        } else {
          _errorMessage = '权限不足：仅管理员可访问此页面';
          _isLoading = false;
        }
      });

      // Check if token is expired
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'JWT token已过期，请重新登录';
        });
        return;
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
      final fines = await fineApi.apiFinesGet() ?? [];
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
        final fines = await fineApi.apiFinesPayeePayeeGet(payee: query) ?? [];
        setState(() {
          _fineList = fines;
          _isLoading = false;
          if (_fineList.isEmpty) _errorMessage = '未找到缴款人为 $query 的罚款信息';
        });
      } else if (_searchType == 'timeRange' && _dateRange != null) {
        final fines = await fineApi.apiFinesTimeRangeGet(
              startTime: _dateRange!.start.toIso8601String(),
              endTime: _dateRange!.end.toIso8601String(),
            ) ??
            [];
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
        data: controller.currentBodyTheme.value,
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
    Get.to(() => const AddFinePage())?.then((value) {
      if (value == true && mounted) _fetchFines();
    });
  }

  void _goToDetailPage(FineInformation fine) {
    Get.to(() => FineDetailPage(fine: fine))?.then((value) {
      if (value == true && mounted) _fetchFines();
    });
  }

  Future<void> _deleteFine(int fineId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此罚款信息吗？');
    if (!confirmed) return;

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
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    final themeData = controller.currentBodyTheme.value;
    return await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
            data: themeData,
            child: AlertDialog(
              backgroundColor: themeData.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(title,
                  style: themeData.textTheme.titleMedium
                      ?.copyWith(color: themeData.colorScheme.onSurface)),
              content: Text(content,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('确定',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.primary)),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      if (!_isLoading && _errorMessage.isNotEmpty) {
        return Theme(
          data: themeData,
          child: CupertinoPageScaffold(
            backgroundColor: themeData.colorScheme.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: themeData.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage.contains('登录'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () => Get.offAllNamed(AppPages.login),
                        style: themeData.elevatedButtonTheme.style,
                        child: const Text('前往登录'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '罚款信息列表',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Icon(
                    CupertinoIcons.calendar_today,
                    color: themeData.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _createFine,
                  child: Icon(
                    CupertinoIcons.add,
                    color: themeData.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(themeData),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CupertinoActivityIndicator(
                              color: themeData.colorScheme.primary,
                              radius: 16.0,
                            ),
                          )
                        : _fineList.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无罚款信息',
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color:
                                        themeData.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : CupertinoScrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6.0,
                                thicknessWhileDragging: 10.0,
                                child: RefreshIndicator(
                                  onRefresh: _fetchFines,
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _fineList.length,
                                    itemBuilder: (context, index) {
                                      final fine = _fineList[index];
                                      return _buildFineCard(fine, themeData);
                                    },
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 2,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _payeeController,
                style: TextStyle(color: themeData.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: _searchType == 'payee' ? '按缴款人搜索' : '按时间范围搜索（已选择）',
                  labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                  prefixIcon:
                      Icon(Icons.search, color: themeData.colorScheme.primary),
                  suffixIcon: _payeeController.text.isNotEmpty ||
                          _dateRange != null
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
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
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
      ),
    );
  }

  Widget _buildFineCard(FineInformation fine, ThemeData themeData) {
    return Card(
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '罚款金额: ${fine.fineAmount ?? 0} 元',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '缴款人: ${fine.payee ?? "未知"}\n时间: ${formatDate(fine.fineTime)}\n状态: ${fine.status ?? "Pending"}',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _goToDetailPage(fine),
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

  final DashboardController controller = Get.find<DashboardController>();

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
            ? DateTime.parse("${_dateController.text.trim()}T00:00:00")
                .toIso8601String()
            : null,
        status: 'Pending',
        idempotencyKey: idempotencyKey,
      );

      await fineApi.apiFinesPost(
        fineInformation: fine,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建罚款成功！');
      if (mounted) Get.back(result: true);
    } catch (e) {
      _showSnackBar('创建罚款失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '添加新罚款',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: _buildFineForm(themeData),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFineForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(
            themeData, '车牌号', Icons.directions_car, _plateNumberController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '罚款金额 (元)', Icons.money, _fineAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            required: true),
        const SizedBox(height: 12),
        _buildTextField(themeData, '缴款人', Icons.person, _payeeController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '银行账号', Icons.account_balance, _accountNumberController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '银行名称', Icons.account_balance_wallet, _bankController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '收据编号', Icons.receipt, _receiptNumberController),
        const SizedBox(height: 12),
        _buildTextField(themeData, '备注', Icons.notes, _remarksController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '罚款日期', Icons.calendar_today, _dateController,
            readOnly: true, onTap: _pickDate),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitFine,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('提交'),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData themeData, String label, IconData icon,
      TextEditingController controller,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
      ),
      style: TextStyle(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator:
          required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
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
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final TextEditingController _remarksController = TextEditingController();

  final DashboardController controller = Get.find<DashboardController>();

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

      // Decode the JWT token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
      debugPrint('Decoded JWT: $decodedToken');

      // Extract roles and handle String or List cases
      final rolesData = decodedToken['roles'];
      List<dynamic> roles;
      if (rolesData is String) {
        roles = [rolesData]; // Convert String to single-element List
      } else {
        roles = rolesData as List<dynamic>? ?? []; // Handle List or null
      }
      debugPrint('Processed Roles: $roles');

      setState(() {
        _isAdmin = roles.contains('ADMIN');
        _isLoading = false;
      });

      // Check if token is expired
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() {
          _errorMessage = 'JWT token已过期，请重新登录';
          _isLoading = false;
        });
        return;
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
      if (mounted) Get.back(result: true);
    } catch (e) {
      _showSnackBar('更新状态失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此罚款信息吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await fineApi.apiFinesFineIdDelete(fineId: fineId);
      _showSnackBar('罚款删除成功！');
      if (mounted) Get.back(result: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    final themeData = controller.currentBodyTheme.value;
    return await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
            data: themeData,
            child: AlertDialog(
              backgroundColor: themeData.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(title,
                  style: themeData.textTheme.titleMedium
                      ?.copyWith(color: themeData.colorScheme.onSurface)),
              content: Text(content,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('确定',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.primary)),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      if (_errorMessage.isNotEmpty) {
        return Theme(
          data: themeData,
          child: CupertinoPageScaffold(
            backgroundColor: themeData.colorScheme.surface,
            child: Center(
              child: Text(
                _errorMessage,
                style: themeData.textTheme.titleMedium?.copyWith(
                  color: themeData.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '罚款详细信息',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
            ),
            trailing: _isAdmin
                ? GestureDetector(
                    onTap: () => _showActions(widget.fine),
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: themeData.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : CupertinoScrollbar(
                      controller: ScrollController(),
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 2,
                              color: themeData.colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                        '罚款金额',
                                        '${widget.fine.fineAmount ?? 0} 元',
                                        themeData),
                                    _buildDetailRow('缴款人',
                                        widget.fine.payee ?? '未知', themeData),
                                    _buildDetailRow(
                                        '罚款时间',
                                        formatDate(widget.fine.fineTime),
                                        themeData),
                                    _buildDetailRow('车牌号', '未知', themeData),
                                    // Placeholder, see note
                                    _buildDetailRow(
                                        '银行账号',
                                        widget.fine.accountNumber ?? '未知',
                                        themeData),
                                    _buildDetailRow('银行名称',
                                        widget.fine.bank ?? '未知', themeData),
                                    _buildDetailRow(
                                        '收据编号',
                                        widget.fine.receiptNumber ?? '未知',
                                        themeData),
                                    _buildDetailRow(
                                        '状态',
                                        widget.fine.status ?? 'Pending',
                                        themeData),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _remarksController,
                                      decoration: InputDecoration(
                                        labelText: '备注',
                                        prefixIcon: Icon(Icons.notes,
                                            color:
                                                themeData.colorScheme.primary),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: themeData
                                            .colorScheme.surfaceContainerLow,
                                        labelStyle: TextStyle(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant),
                                      ),
                                      style: TextStyle(
                                          color:
                                              themeData.colorScheme.onSurface),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  void _showActions(FineInformation fine) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (fine.status == 'Pending')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _updateFineStatus(fine.fineId ?? 0, 'Approved');
              },
              child: const Text('批准'),
            ),
          if (fine.status == 'Pending')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _updateFineStatus(fine.fineId ?? 0, 'Rejected');
              },
              child: const Text('拒绝'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteFine(fine.fineId ?? 0);
            },
            isDestructiveAction: true,
            child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
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
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
