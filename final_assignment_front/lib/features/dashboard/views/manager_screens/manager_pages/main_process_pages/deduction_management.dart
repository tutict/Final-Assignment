import 'dart:developer' as developer;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '无';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final List<DeductionInformation> _deductions = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  final String _searchType =
      'handler'; // Default to handler since driverLicense is removed
  DateTime? _startTime;
  DateTime? _endTime;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _loadDeductions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeductions({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _deductions.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    try {
      await deductionApi.initializeWithJwt();
      List<DeductionInformation> deductions = [];
      if (searchQuery.isEmpty && _startTime == null && _endTime == null) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
      } else if (_searchType == 'handler' && searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsByHandlerGet(
              handler: searchQuery,
            ) ??
            [];
      } else if (_startTime != null && _endTime != null) {
        deductions = await deductionApi.apiDeductionsByTimeRangeGet(
              startTime: formatDateTime(_startTime),
              endTime: formatDateTime(_endTime),
            ) ??
            [];
      }

      setState(() {
        _deductions.addAll(deductions);
        if (deductions.length < _pageSize) _hasMore = false;
        if (_deductions.isEmpty && _currentPage == 1) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
                  ? '未找到符合条件的扣分记录'
                  : '暂无扣分记录';
        }
      });
      developer.log('Loaded deductions: ${_deductions.length}');
    } catch (e) {
      developer.log('Error fetching deductions: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is ApiException && e.code == 404) {
          _deductions.clear();
          _errorMessage = '未找到符合条件的扣分记录，可能 $_searchType "$searchQuery" 不存在';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取扣分记录失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreDeductions() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _loadDeductions(query: _searchController.text);
  }

  Future<void> _refreshDeductions() async {
    _searchController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
    });
    await _loadDeductions(reset: true);
  }

  Future<void> _searchDeductions() async {
    final query = _searchController.text.trim();
    await _loadDeductions(reset: true, query: query);
  }

  void _createDeduction() {
    Get.to(() => const AddDeductionPage())?.then((value) {
      if (value == true && mounted) _loadDeductions(reset: true);
    });
  }

  void _goToDetailPage(DeductionInformation deduction) {
    Get.to(() => DeductionDetailPage(deduction: deduction))?.then((value) {
      if (value == true && mounted) _loadDeductions(reset: true);
    });
  }

  Future<void> _deleteDeduction(int deductionId) async {
    _showDeleteConfirmationDialog('删除', () async {
      setState(() => _isLoading = true);
      try {
        await deductionApi.apiDeductionsDeductionIdDelete(
            deductionId: deductionId);
        _showSnackBar('删除扣分记录成功！');
        _loadDeductions(reset: true);
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
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
            '您确定要$action此扣分记录吗？此操作不可撤销。',
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
                    hintText: '搜索处理人',
                    // Only handler search remains
                    hintStyle: TextStyle(
                        color:
                            themeData.colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              _loadDeductions(reset: true);
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
                  onSubmitted: (value) => _searchDeductions(),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              // Removed the DropdownButton since only handler search is supported
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _startTime != null && _endTime != null
                      ? '时间范围: ${formatDateTime(_startTime)} 至 ${formatDateTime(_endTime)}'
                      : '选择时间范围',
                  style: TextStyle(
                    color: _startTime != null && _endTime != null
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.date_range,
                    color: themeData.colorScheme.primary),
                tooltip: '按时间范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择时间范围',
                    cancelText: '取消',
                    confirmText: '确定',
                    fieldStartHintText: '开始日期',
                    fieldEndHintText: '结束日期',
                    builder: (context, child) =>
                        Theme(data: themeData, child: child!),
                  );
                  if (range != null) {
                    setState(() {
                      _startTime = range.start;
                      _endTime = range.end;
                    });
                    _searchDeductions();
                  }
                },
              ),
              if (_startTime != null && _endTime != null)
                IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  tooltip: '清除日期范围',
                  onPressed: () {
                    setState(() {
                      _startTime = null;
                      _endTime = null;
                    });
                    _searchDeductions();
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
          title: Text(
            '扣分信息管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshDeductions,
              tooltip: '刷新列表',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createDeduction,
              tooltip: '添加新扣分记录',
            ),
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
          onRefresh: _refreshDeductions,
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
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
                        _loadMoreDeductions();
                      }
                      return false;
                    },
                    child: _isLoading && _currentPage == 1
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  themeData.colorScheme.primary),
                            ),
                          )
                        : _errorMessage.isNotEmpty && _deductions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _errorMessage,
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_errorMessage.contains('未授权'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Get.offAllNamed(AppPages.login),
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
                                    _deductions.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _deductions.length && _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final deduction = _deductions[index];
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
                                        '扣分: ${deduction.deductedPoints ?? 0} 分',
                                        style: themeData.textTheme.titleMedium
                                            ?.copyWith(
                                          color:
                                              themeData.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '驾驶证号: ${deduction.driverLicenseNumber ?? '无'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '时间: ${formatDateTime(deduction.deductionTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '处理人: ${deduction.handler ?? '未记录'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              size: 18,
                                              color:
                                                  themeData.colorScheme.error,
                                            ),
                                            onPressed: () => _deleteDeduction(
                                                deduction.deductionId ?? 0),
                                            tooltip: '删除扣分记录',
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _goToDetailPage(deduction),
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
          onPressed: _createDeduction,
          backgroundColor: themeData.colorScheme.primary,
          foregroundColor: themeData.colorScheme.onPrimary,
          tooltip: '添加新扣分记录',
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}

class AddDeductionPage extends StatefulWidget {
  const AddDeductionPage({super.key});

  @override
  State<AddDeductionPage> createState() => _AddDeductionPageState();
}

class _AddDeductionPageState extends State<AddDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
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
      await deductionApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final date = _dateController.text.trim();
      final points = int.tryParse(_deductedPointsController.text.trim()) ?? 0;

      if (points <= 0 || points > 12) throw Exception('扣分分数必须在 1 到 12 之间');

      final deduction = DeductionInformation(
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints: points,
        deductionTime: DateTime.parse('${date}T00:00:00'),
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      await deductionApi.apiDeductionsPost(
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('创建扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
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
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() => _dateController.text = formatDateTime(pickedDate));
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
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
                color: themeData.colorScheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 1.5),
          ),
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '添加扣分信息',
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
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
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

class EditDeductionPage extends StatefulWidget {
  final DeductionInformation deduction;

  const EditDeductionPage({super.key, required this.deduction});

  @override
  State<EditDeductionPage> createState() => _EditDeductionPageState();
}

class _EditDeductionPageState extends State<EditDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
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
      await deductionApi.initializeWithJwt();
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    _driverLicenseNumberController.text =
        widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text =
        (widget.deduction.deductedPoints ?? 0).toString();
    _handlerController.text = widget.deduction.handler ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text = formatDateTime(widget.deduction.deductionTime);
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
    if (!_formKey.currentState!.validate()) return;
    if (widget.deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法更新', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final date = _dateController.text.trim();
      final points = int.tryParse(_deductedPointsController.text.trim()) ?? 0;

      if (points <= 0 || points > 12) throw Exception('扣分分数必须在 1 到 12 之间');

      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints: points,
        deductionTime: DateTime.parse('${date}T00:00:00'),
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId!,
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('更新扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
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
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() => _dateController.text = formatDateTime(pickedDate));
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
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
                color: themeData.colorScheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 1.5),
          ),
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '编辑扣分信息',
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
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
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
                          child: const Text('保存'),
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

class DeductionDetailPage extends StatefulWidget {
  final DeductionInformation deduction;

  const DeductionDetailPage({super.key, required this.deduction});

  @override
  State<DeductionDetailPage> createState() => _DeductionDetailPageState();
}

class _DeductionDetailPageState extends State<DeductionDetailPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  late DeductionInformation _deduction;
  bool _isLoading = false;
  bool _isEditable = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _deduction = widget.deduction;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      _isEditable = true; // 假设管理员权限，实际需根据角色判断
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDeduction() async {
    if (_deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法删除', isError: true);
      return;
    }

    _showDeleteConfirmationDialog('删除', () async {
      setState(() => _isLoading = true);
      try {
        await deductionApi.apiDeductionsDeductionIdDelete(
            deductionId: _deduction.deductionId!);
        _showSnackBar('扣分记录删除成功！');
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar(_formatErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
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
            '您确定要$action此扣分记录吗？此操作不可撤销。',
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

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '扣分详情',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isEditable
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Get.to(() => EditDeductionPage(deduction: _deduction))
                          ?.then((value) {
                        if (value == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    },
                    tooltip: '编辑扣分记录',
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: _deleteDeduction,
                    tooltip: '删除扣分记录',
                  ),
                ]
              : [],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(themeData.colorScheme.primary),
                ),
              )
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
                          _buildDetailRow(
                              '扣分ID',
                              _deduction.deductionId?.toString() ?? '未提供',
                              themeData),
                          _buildDetailRow('驾驶证号',
                              _deduction.driverLicenseNumber ?? '无', themeData),
                          _buildDetailRow('扣分分数',
                              '${_deduction.deductedPoints ?? 0} 分', themeData),
                          _buildDetailRow(
                              '扣分时间',
                              formatDateTime(_deduction.deductionTime),
                              themeData),
                          _buildDetailRow(
                              '处理人', _deduction.handler ?? '无', themeData),
                          _buildDetailRow(
                              '备注', _deduction.remarks ?? '无', themeData),
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
