import 'dart:developer' as developer;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
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
  late DeductionInformationControllerApi deductionApi;
  List<DeductionInformation> _deductions = [];
  List<DeductionInformation> _filteredDeductions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _driverLicenseController = TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  late ScrollController _scrollController;
  DateTime? _startTime;
  DateTime? _endTime;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    deductionApi = DeductionInformationControllerApi();
    _scrollController = ScrollController();
    _loadDeductions();
  }

  @override
  void dispose() {
    _driverLicenseController.dispose();
    _handlerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDeductions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await deductionApi.initializeWithJwt();
      final deductions = await deductionApi.apiDeductionsGet() ?? [];
      setState(() {
        _deductions = deductions;
        _filteredDeductions = deductions;
        _isLoading = false;
        if (_deductions.isEmpty) _errorMessage = '暂无扣分记录';
      });
      developer.log('Loaded deductions: ${_deductions.length}');
    } catch (e) {
      developer.log('Error fetching deductions: $e', stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录') || e.toString().contains('403')) _redirectToLogin();
      });
    }
  }

  void _applyFilters() {
    final license = _driverLicenseController.text.trim().toLowerCase();
    final handler = _handlerController.text.trim().toLowerCase();

    setState(() {
      _isLoading = false;
      _errorMessage = '';
      if (license.isEmpty && handler.isEmpty && _startTime == null && _endTime == null) {
        _filteredDeductions = _deductions;
      } else {
        _filteredDeductions = _deductions.where((deduction) {
          final driverLicense = (deduction.driverLicenseNumber ?? '').toLowerCase();
          final deductionHandler = (deduction.handler ?? '').toLowerCase();
          final deductionTime = deduction.deductionTime;
          return (license.isEmpty || driverLicense.contains(license)) &&
              (handler.isEmpty || deductionHandler.contains(handler)) &&
              (_startTime == null || deductionTime != null && deductionTime.isAfter(_startTime!)) &&
              (_endTime == null || deductionTime != null && deductionTime.isBefore(_endTime!));
        }).toList();
      }
      if (_filteredDeductions.isEmpty) {
        _errorMessage = license.isNotEmpty || handler.isNotEmpty || (_startTime != null && _endTime != null)
            ? '未找到符合条件的扣分记录'
            : '暂无扣分记录';
      }
      developer.log('Filtered deductions: ${_filteredDeductions.length}');
    });
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Get.offAllNamed(AppPages.login);
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
      ),
    );
  }

  void _goToDetailPage(DeductionInformation deduction) {
    Get.to(() => DeductionDetailPage(deduction: deduction))?.then((value) {
      if (value == true && mounted) _loadDeductions();
    });
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
              '扣分信息管理',
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
            trailing: GestureDetector(
              onTap: () => Get.to(() => const AddDeductionPage())?.then((value) {
                if (value == true && mounted) _loadDeductions();
              }),
              child: Icon(
                CupertinoIcons.add,
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
                        : _errorMessage.isNotEmpty
                        ? Center(
                      child: Text(
                        _errorMessage,
                        style: themeData.textTheme.bodyLarge?.copyWith(
                          color: themeData.colorScheme.error,
                          fontSize: 18,
                        ),
                      ),
                    )
                        : CupertinoScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: RefreshIndicator(
                        onRefresh: _loadDeductions,
                        color: themeData.colorScheme.primary,
                        backgroundColor: themeData.colorScheme.surfaceContainer,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _filteredDeductions.length,
                          itemBuilder: (context, index) {
                            final deduction = _filteredDeductions[index];
                            return _buildDeductionCard(deduction, themeData);
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _driverLicenseController,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按驾驶证号搜索',
                      labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.drive_eta, color: themeData.colorScheme.primary),
                      suffixIcon: _driverLicenseController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _driverLicenseController.clear();
                          _applyFilters();
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
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _handlerController,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按处理人搜索',
                      labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.person, color: themeData.colorScheme.primary),
                      suffixIcon: _handlerController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _handlerController.clear();
                          _applyFilters();
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
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.date_range, color: themeData.colorScheme.primary),
                  tooltip: '按日期范围搜索',
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('zh', 'CN'),
                      helpText: '选择日期范围',
                      cancelText: '取消',
                      confirmText: '确定',
                      fieldStartHintText: '开始日期',
                      fieldEndHintText: '结束日期',
                      builder: (context, child) => Theme(data: themeData, child: child!),
                    );
                    if (range != null) {
                      setState(() {
                        _startTime = range.start;
                        _endTime = range.end;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionCard(DeductionInformation deduction, ThemeData themeData) {
    return Card(
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '扣分: ${deduction.deductedPoints ?? 0} 分 (ID: ${deduction.deductionId ?? "无"})',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '驾驶证号: ${deduction.driverLicenseNumber ?? "无"}\n时间: ${formatDateTime(deduction.deductionTime)}\n处理人: ${deduction.handler ?? "未记录"}',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _goToDetailPage(deduction),
      ),
    );
  }
}

class AddDeductionPage extends StatefulWidget {
  const AddDeductionPage({super.key});

  @override
  State<AddDeductionPage> createState() => _AddDeductionPageState();
}

class _AddDeductionPageState extends State<AddDeductionPage> {
  final deductionApi = DeductionInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _deductedPointsController = TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

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
      await deductionApi.initializeWithJwt();

      final license = _driverLicenseNumberController.text.trim();
      final points = int.tryParse(_deductedPointsController.text.trim()) ?? 0;
      final date = _dateController.text.trim();

      if (points <= 0 || points > 12) throw Exception('扣分分数必须在 1 到 12 之间');

      final deduction = DeductionInformation(
        driverLicenseNumber: license,
        deductedPoints: points,
        deductionTime: DateTime.parse('${date}T00:00:00'),
        handler: _handlerController.text.trim().isEmpty ? null : _handlerController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
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
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
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
      builder: (context, child) => Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text = formatDateTime(pickedDate);
      });
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              '添加扣分信息',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeData.colorScheme.onPrimaryContainer),
              onPressed: () => Get.back(),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            elevation: 1,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: themeData.colorScheme.primary))
                  : Form(
                key: _formKey,
                child: SingleChildScrollView(child: _buildDeductionForm(themeData)),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeductionForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '驾驶证号 *', Icons.drive_eta, _driverLicenseNumberController, required: true),
        const SizedBox(height: 16),
        _buildTextField(themeData, '扣分分数 *', Icons.score, _deductedPointsController,
            keyboardType: TextInputType.number, required: true),
        const SizedBox(height: 16),
        _buildTextField(themeData, '处理人', Icons.person, _handlerController),
        const SizedBox(height: 16),
        _buildTextField(themeData, '备注', Icons.notes, _remarksController),
        const SizedBox(height: 16),
        _buildTextField(themeData, '扣分时间 *', Icons.date_range, _dateController,
            readOnly: true, onTap: _pickDate, required: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDeduction,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('提交'),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData themeData, String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool required = false}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: themeData.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
    );
  }
}

class EditDeductionPage extends StatefulWidget {
  final DeductionInformation deduction;

  const EditDeductionPage({super.key, required this.deduction});

  @override
  State<EditDeductionPage> createState() => _EditDeductionPageState();
}

class _EditDeductionPageState extends State<EditDeductionPage> {
  final deductionApi = DeductionInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _deductedPointsController = TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _driverLicenseNumberController.text = widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text = (widget.deduction.deductedPoints ?? 0).toString();
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
      await deductionApi.initializeWithJwt();

      final license = _driverLicenseNumberController.text.trim();
      final points = int.tryParse(_deductedPointsController.text.trim()) ?? 0;
      final date = _dateController.text.trim();

      if (points <= 0 || points > 12) throw Exception('扣分分数必须在 1 到 12 之间');

      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: license,
        deductedPoints: points,
        deductionTime: DateTime.parse('${date}T00:00:00'),
        handler: _handlerController.text.trim().isEmpty ? null : _handlerController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId!, // Non-null assertion after check
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
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
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
      builder: (context, child) => Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text = formatDateTime(pickedDate);
      });
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
              '编辑扣分信息',
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
                  ? Center(child: CupertinoActivityIndicator(color: themeData.colorScheme.primary, radius: 16.0))
                  : Form(
                key: _formKey,
                child: SingleChildScrollView(child: _buildDeductionForm(themeData)),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeductionForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '驾驶证号 *', Icons.drive_eta, _driverLicenseNumberController, required: true),
        const SizedBox(height: 16),
        _buildTextField(themeData, '扣分分数 *', Icons.score, _deductedPointsController,
            keyboardType: TextInputType.number, required: true),
        const SizedBox(height: 16),
        _buildTextField(themeData, '处理人', Icons.person, _handlerController),
        const SizedBox(height: 16),
        _buildTextField(themeData, '备注', Icons.notes, _remarksController),
        const SizedBox(height: 16),
        _buildTextField(themeData, '扣分时间 *', Icons.date_range, _dateController,
            readOnly: true, onTap: _pickDate, required: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDeduction,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData themeData, String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool required = false}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: themeData.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
    );
  }
}

class DeductionDetailPage extends StatefulWidget {
  final DeductionInformation deduction;

  const DeductionDetailPage({super.key, required this.deduction});

  @override
  State<DeductionDetailPage> createState() => _DeductionDetailPageState();
}

class _DeductionDetailPageState extends State<DeductionDetailPage> {
  final deductionApi = DeductionInformationControllerApi();
  late DeductionInformation _deduction;
  bool _isLoading = false;
  final TextEditingController _remarksController = TextEditingController();

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _deduction = widget.deduction;
    _remarksController.text = _deduction.remarks ?? '';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _updateDeduction() async {
    if (_deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法更新', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();

      final updatedDeduction = DeductionInformation(
        deductionId: _deduction.deductionId,
        driverLicenseNumber: _deduction.driverLicenseNumber,
        deductedPoints: _deduction.deductedPoints,
        deductionTime: _deduction.deductionTime,
        handler: _deduction.handler,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: _deduction.deductionId!, // Non-null assertion after check
        deductionInformation: updatedDeduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('更新扣分记录成功！');
      if (mounted) {
        setState(() => _deduction = updatedDeduction);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDeduction() async {
    if (_deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法删除', isError: true);
      return;
    }

    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此扣分记录吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      await deductionApi.apiDeductionsDeductionIdDelete(deductionId: _deduction.deductionId!);
      _showSnackBar('扣分记录删除成功！');
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
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
              title,
              style: themeData.textTheme.titleMedium?.copyWith(color: themeData.colorScheme.onSurface)),
          content: Text(
              content,
              style: themeData.textTheme.bodyMedium?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消',
                  style: themeData.textTheme.labelMedium?.copyWith(color: themeData.colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('确定',
                  style: themeData.textTheme.labelMedium?.copyWith(color: themeData.colorScheme.primary)),
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
      final deductionId = _deduction.deductionId?.toString() ?? '未提供';
      final license = _deduction.driverLicenseNumber ?? '无';
      final points = _deduction.deductedPoints ?? 0;
      final time = formatDateTime(_deduction.deductionTime);
      final handler = _deduction.handler ?? '无';
      final remarks = _deduction.remarks ?? '无';

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '扣分详情',
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
            trailing: GestureDetector(
              onTap: () => Get.to(() => EditDeductionPage(deduction: _deduction))?.then((value) {
                if (value == true && mounted) _loadDeductionDetails();
              }),
              child: Icon(
                CupertinoIcons.pencil,
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
                  ? Center(child: CupertinoActivityIndicator(color: themeData.colorScheme.primary, radius: 16.0))
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('扣分ID', deductionId, themeData),
                              _buildDetailRow('驾驶证号', license, themeData),
                              _buildDetailRow('扣分分数', '$points 分', themeData),
                              _buildDetailRow('扣分时间', time, themeData),
                              _buildDetailRow('处理人', handler, themeData),
                              _buildDetailRow('备注', remarks, themeData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _remarksController,
                        style: TextStyle(color: themeData.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: '编辑备注',
                          prefixIcon: Icon(Icons.notes, color: themeData.colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: themeData.colorScheme.surfaceContainerLow,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _updateDeduction,
                            icon: const Icon(CupertinoIcons.checkmark),
                            label: const Text('保存备注'),
                            style: themeData.elevatedButtonTheme.style,
                          ),
                          ElevatedButton.icon(
                            onPressed: _deleteDeduction,
                            icon: const Icon(CupertinoIcons.trash),
                            label: const Text('删除'),
                            style: themeData.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStatePropertyAll(themeData.colorScheme.error),
                              foregroundColor: WidgetStatePropertyAll(themeData.colorScheme.onError),
                            ),
                          ),
                        ],
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

  Future<void> _loadDeductionDetails() async {
    if (_deduction.deductionId == null) {
      _showSnackBar('扣分记录ID无效，无法加载详情', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      final updatedDeduction = await deductionApi.apiDeductionsDeductionIdGet(
          deductionId: _deduction.deductionId!); // Non-null assertion after check
      if (updatedDeduction != null && mounted) {
        setState(() {
          _deduction = updatedDeduction;
          _remarksController.text = _deduction.remarks ?? '';
        });
      }
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

}