import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
    return date ?? '无';
  }
}

/// FineList 页面：管理员才能访问
class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListState();
}

class _FineListState extends State<FineList> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<FineInformation> _fineList = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchType = 'payee'; // 默认搜索类型为缴款人

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      await fineApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) await _fetchFines(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT');

      // 直接解析JWT
      final decodedToken = JwtDecoder.decode(jwtToken);
      final roles = decodedToken['roles'] is String
          ? [decodedToken['roles']] // 如果是字符串，转换为列表
          : (decodedToken['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [];

      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFines({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _fineList.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    debugPrint(
        'Fetching fines with query: $searchQuery, page: $_currentPage, searchType: $_searchType');

    try {
      List<FineInformation> fines = [];
      if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
        fines = await fineApi.apiFinesGet() ?? [];
      } else if (_searchType == 'payee' && searchQuery.isNotEmpty) {
        fines = await fineApi.apiFinesPayeePayeeGet(payee: searchQuery) ?? [];
      } else if (_startDate != null && _endDate != null) {
        fines = await fineApi.apiFinesTimeRangeGet(
              startTime: _startDate!.toIso8601String(),
              endTime: _endDate!.toIso8601String(),
            ) ??
            [];
      }

      setState(() {
        _fineList.addAll(fines);
        if (fines.length < _pageSize) _hasMore = false;
        if (_fineList.isEmpty && _currentPage == 1) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startDate != null && _endDate != null)
                  ? '未找到符合条件的罚款信息'
                  : '当前没有罚款记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('404')) {
          _fineList.clear();
          _errorMessage =
              '未找到符合条件的罚款信息，可能${_searchType == "payee" ? "缴款人" : "时间范围"} "$searchQuery" 不存在';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取罚款信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreFines() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchFines(query: _searchController.text);
  }

  Future<void> _refreshFines() async {
    _searchController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    await _fetchFines(reset: true);
  }

  Future<void> _searchFines() async {
    final query = _searchController.text.trim();
    await _fetchFines(reset: true, query: query);
  }

  void _createFine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFinePage()),
    ).then((value) {
      if (value == true && mounted) _fetchFines(reset: true);
    });
  }

  void _goToDetailPage(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FineDetailPage(fine: fine)),
    ).then((value) {
      if (value == true && mounted) _fetchFines(reset: true);
    });
  }

  Future<void> _deleteFine(int fineId) async {
    _showDeleteConfirmationDialog('删除', () async {
      setState(() => _isLoading = true);
      try {
        await fineApi.apiFinesFineIdDelete(fineId: fineId);
        _showSnackBar('删除罚款成功！');
        _fetchFines(reset: true);
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    });
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

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: Text(
            '您确定要$action此罚款吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: _searchType == 'payee' ? '搜索缴款人' : '搜索时间范围（已选择）',
                    hintStyle: TextStyle(
                        color:
                            themeData.colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty ||
                            (_startDate != null && _endDate != null)
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                              _fetchFines(reset: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
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
                  onSubmitted: (value) => _searchFines(),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _searchType,
                onChanged: (String? newValue) {
                  setState(() {
                    _searchType = newValue!;
                    _searchController.clear();
                    _startDate = null;
                    _endDate = null;
                    _fetchFines(reset: true);
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _startDate != null && _endDate != null
                      ? '罚款日期范围: ${formatDate(_startDate.toString())} 至 ${formatDate(_endDate.toString())}'
                      : '选择罚款日期范围',
                  style: TextStyle(
                    color: _startDate != null && _endDate != null
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.date_range,
                    color: themeData.colorScheme.primary),
                tooltip: '按罚款日期范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择罚款日期范围',
                    cancelText: '取消',
                    confirmText: '确定',
                    fieldStartHintText: '开始日期',
                    fieldEndHintText: '结束日期',
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                          data: controller.currentBodyTheme.value,
                          child: child!);
                    },
                  );
                  if (range != null) {
                    setState(() {
                      _startDate = range.start;
                      _endDate = range.end;
                      _searchType = 'timeRange';
                    });
                    _searchFines();
                  }
                },
              ),
              if (_startDate != null && _endDate != null)
                IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  tooltip: '清除日期范围',
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _searchFines();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('罚款管理',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshFines,
                tooltip: '刷新罚款列表'),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createFine,
                tooltip: '添加新罚款信息'),
            IconButton(
              icon: Icon(themeData.brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshFines,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchField(themeData),
                const SizedBox(height: 12),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          _hasMore) {
                        _loadMoreFines();
                      }
                      return false;
                    },
                    child: _isLoading && _currentPage == 1
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    themeData.colorScheme.primary)))
                        : _errorMessage.isNotEmpty && _fineList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _errorMessage,
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                              color:
                                                  themeData.colorScheme.error,
                                              fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_errorMessage.contains('未授权'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pushReplacementNamed(
                                                  context, AppPages.login),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeData.colorScheme.primary,
                                            foregroundColor:
                                                themeData.colorScheme.onPrimary,
                                          ),
                                          child: const Text('重新登录'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    _fineList.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _fineList.length && _hasMore) {
                                    return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  }
                                  final fine = _fineList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      title: Text(
                                        '金额: ${fine.fineAmount ?? 0} 元',
                                        style: themeData.textTheme.titleMedium
                                            ?.copyWith(
                                                color: themeData
                                                    .colorScheme.onSurface,
                                                fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('缴款人: ${fine.payee ?? '未知'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '时间: ${formatDate(fine.fineTime)}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '状态: ${fine.status ?? 'Pending'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 18, color: Colors.red),
                                            onPressed: () =>
                                                _deleteFine(fine.fineId ?? 0),
                                            tooltip: '删除罚款',
                                          ),
                                          Icon(Icons.arrow_forward_ios,
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                              size: 18),
                                        ],
                                      ),
                                      onTap: () => _goToDetailPage(fine),
                                    ),
                                  );
                                },
                              ),
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
    });
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
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await fineApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text = formatDate(pickedDate.toString());
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix}) {
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
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('添加新罚款',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
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
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    required: true),
                                _buildTextField(
                                    '缴款人', _payeeController, themeData,
                                    required: true),
                                _buildTextField('银行账号',
                                    _accountNumberController, themeData),
                                _buildTextField(
                                    '银行名称', _bankController, themeData),
                                _buildTextField('收据编号',
                                    _receiptNumberController, themeData),
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
    });
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

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      await fineApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ROLE_ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
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
    _showDeleteConfirmationDialog('删除', () async {
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
    });
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

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: Text(
            '您确定要$action此罚款吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: themeData.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          Expanded(
            child: Text(value,
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      if (_errorMessage.isNotEmpty) {
        return Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage,
                    style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.error,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                if (_errorMessage.contains('登录'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppPages.login),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary),
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
          title: Text('罚款详情',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isAdmin
              ? [
                  if (widget.fine.status == 'Pending') ...[
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => _updateFineStatus(
                          widget.fine.fineId ?? 0, 'Approved'),
                      tooltip: '批准罚款',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _updateFineStatus(
                          widget.fine.fineId ?? 0, 'Rejected'),
                      tooltip: '拒绝罚款',
                    ),
                  ],
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: () => _deleteFine(widget.fine.fineId ?? 0),
                    tooltip: '删除罚款',
                  ),
                ]
              : [],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(themeData.colorScheme.primary)))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('罚款金额',
                              '${widget.fine.fineAmount ?? 0} 元', themeData),
                          _buildDetailRow(
                              '缴款人', widget.fine.payee ?? '未知', themeData),
                          _buildDetailRow('罚款时间',
                              formatDate(widget.fine.fineTime), themeData),
                          _buildDetailRow(
                              '车牌号', '未知', themeData), // Placeholder
                          _buildDetailRow('银行账号',
                              widget.fine.accountNumber ?? '无', themeData),
                          _buildDetailRow(
                              '银行名称', widget.fine.bank ?? '无', themeData),
                          _buildDetailRow('收据编号',
                              widget.fine.receiptNumber ?? '无', themeData),
                          _buildDetailRow(
                              '状态', widget.fine.status ?? 'Pending', themeData),
                          _buildDetailRow(
                              '备注', widget.fine.remarks ?? '无', themeData),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    });
  }
}
