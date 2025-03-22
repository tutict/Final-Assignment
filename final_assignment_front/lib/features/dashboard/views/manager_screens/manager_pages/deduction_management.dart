import 'dart:developer' as developer;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  late DeductionInformationControllerApi deductionApi;
  List<DeductionInformation> _deductions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _driverLicenseController =
      TextEditingController();
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
      _deductions = await deductionApi.apiDeductionsGet() ?? [];
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error fetching deductions: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载扣分信息失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await deductionApi.initializeWithJwt();
      if (_driverLicenseController.text.isNotEmpty) {
        final deduction = await deductionApi.apiDeductionsLicenseLicenseGet(
            license: _driverLicenseController.text.trim());
        _deductions = deduction != null ? [deduction] : [];
      } else if (_handlerController.text.isNotEmpty) {
        _deductions = await deductionApi.apiDeductionsHandlerHandlerGet(
                handler: _handlerController.text.trim()) ??
            [];
      } else if (_startTime != null && _endTime != null) {
        _deductions = await deductionApi.apiDeductionsTimeRangeGet(
              startTime: _startTime!.toIso8601String(),
              endTime: _endTime!.toIso8601String(),
            ) ??
            [];
      } else {
        _deductions = await deductionApi.apiDeductionsGet() ?? [];
      }
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error applying filters: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _deleteDeduction(int deductionId) async {
    try {
      await deductionApi.initializeWithJwt();
      await deductionApi.apiDeductionsDeductionIdDelete(
          deductionId: deductionId.toString());
      _showSnackBar('删除扣分记录成功！');
      _loadDeductions();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Get.offAllNamed(AppPages.login);
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
              onTap: () => Get.to(() => const AddDeductionPage())?.then(
                  (value) =>
                      value == true && mounted ? _loadDeductions() : null),
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
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.error,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : _deductions.isEmpty
                                ? Center(
                                    child: Text(
                                      '暂无扣分记录',
                                      style: themeData.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
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
                                      onRefresh: _applyFilters,
                                      color: themeData.colorScheme.primary,
                                      backgroundColor: themeData
                                          .colorScheme.surfaceContainer,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: _deductions.length,
                                        itemBuilder: (context, index) {
                                          final deduction = _deductions[index];
                                          return _buildDeductionCard(
                                              deduction, themeData);
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
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.drive_eta,
                          color: themeData.colorScheme.primary),
                      suffixIcon: _driverLicenseController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
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
                    onSubmitted: (value) => _applyFilters(),
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
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.person,
                          color: themeData.colorScheme.primary),
                      suffixIcon: _handlerController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
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
                    onSubmitted: (value) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.date_range,
                      color: themeData.colorScheme.primary),
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
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: themeData,
                          child: child!,
                        );
                      },
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

  Widget _buildDeductionCard(
      DeductionInformation deduction, ThemeData themeData) {
    return Card(
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '扣分: ${deduction.deductedPoints ?? 0} 分 (ID: ${deduction.deductionId ?? "无"})',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '时间: ${deduction.deductionTime?.toIso8601String() ?? "未知"}\n处理人: ${deduction.handler ?? "未记录"}',
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
  void dispose() {
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitDeduction() async {
    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      DateTime parsedDate =
          DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();
      String formattedDateTime = "${_dateController.text.trim()}T00:00:00";

      final deduction = DeductionInformation(
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse(formattedDateTime),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
      );
      await deductionApi.apiDeductionsPost(
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('创建扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建扣分记录失败: $e', isError: true);
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
              '添加扣分信息',
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
                  : SingleChildScrollView(
                      child: _buildDeductionForm(themeData)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeductionForm(ThemeData themeData) {
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon:
                Icon(Icons.drive_eta, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deductedPointsController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: Icon(Icons.score, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '处理人',
            prefixIcon:
                Icon(Icons.person, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remarksController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: Icon(Icons.notes, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dateController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '扣分时间',
            prefixIcon:
                Icon(Icons.date_range, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
          readOnly: true,
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              locale: const Locale('zh', 'CN'),
              builder: (context, child) =>
                  Theme(data: themeData, child: child!),
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
          style: themeData.elevatedButtonTheme.style,
          child: const Text('提交'),
        ),
      ],
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
    _initializeFields();
  }

  void _initializeFields() {
    _driverLicenseNumberController.text =
        widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text =
        (widget.deduction.deductedPoints ?? 0).toString();
    _handlerController.text = widget.deduction.handler ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text =
        widget.deduction.deductionTime?.toIso8601String().substring(0, 10) ??
            '';
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
    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      DateTime parsedDate =
          DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();
      String formattedDateTime = "${_dateController.text.trim()}T00:00:00";

      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse(formattedDateTime),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
      );
      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId.toString(),
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('更新扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新扣分记录失败: $e', isError: true);
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
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : SingleChildScrollView(
                      child: _buildDeductionForm(themeData)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeductionForm(ThemeData themeData) {
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon:
                Icon(Icons.drive_eta, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deductedPointsController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: Icon(Icons.score, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '处理人',
            prefixIcon:
                Icon(Icons.person, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remarksController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: Icon(Icons.notes, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dateController,
          style: TextStyle(color: themeData.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: '扣分时间',
            prefixIcon:
                Icon(Icons.date_range, color: themeData.colorScheme.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: themeData.colorScheme.surfaceContainerLow,
            labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          ),
          readOnly: true,
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              locale: const Locale('zh', 'CN'),
              builder: (context, child) =>
                  Theme(data: themeData, child: child!),
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
          style: themeData.elevatedButtonTheme.style,
          child: const Text('保存'),
        ),
      ],
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
  bool _isLoading = false;
  final TextEditingController _remarksController = TextEditingController();

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.deduction.remarks ?? '';
  }

  Future<void> _updateDeduction(
      int deductionId, DeductionInformation deduction) async {
    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      String formattedDateTime = deduction.deductionTime != null
          ? deduction.deductionTime!.toIso8601String()
          : "${DateTime.now().toIso8601String().substring(0, 10)}T00:00:00";

      final updatedDeduction = deduction.copyWith(
        deductionTime: DateTime.parse(formattedDateTime),
        remarks: _remarksController.text.trim(),
      );

      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: deductionId.toString(),
        deductionInformation: updatedDeduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('更新扣分记录成功！');
      if (mounted) {
        setState(
            () => widget.deduction.remarks = _remarksController.text.trim());
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('更新失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDeduction(int deductionId) async {
    setState(() => _isLoading = true);
    try {
      await deductionApi.initializeWithJwt();
      await deductionApi.apiDeductionsDeductionIdDelete(
          deductionId: deductionId.toString());
      _showSnackBar('扣分记录删除成功！');
      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final deductionId = widget.deduction.deductionId?.toString() ?? '未提供';
      final license = widget.deduction.driverLicenseNumber ?? '未提供';
      final points = widget.deduction.deductedPoints ?? 0;
      final time = widget.deduction.deductionTime?.toIso8601String() ?? '未提供';
      final handler = widget.deduction.handler ?? '未提供';
      final remarks = widget.deduction.remarks ?? '未提供';

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
              onTap: () =>
                  Get.to(() => EditDeductionPage(deduction: widget.deduction))
                      ?.then((value) =>
                          value == true && mounted ? setState(() {}) : null),
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
                                        '扣分ID', deductionId, themeData),
                                    _buildDetailRow('驾驶证号', license, themeData),
                                    _buildDetailRow(
                                        '扣分分数', '$points 分', themeData),
                                    _buildDetailRow('扣分时间', time, themeData),
                                    _buildDetailRow('处理人', handler, themeData),
                                    _buildDetailRow('备注', remarks, themeData),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _updateDeduction(
                                      widget.deduction.deductionId ?? 0,
                                      widget.deduction),
                                  icon: const Icon(CupertinoIcons.checkmark),
                                  label: const Text('保存备注'),
                                  style: themeData.elevatedButtonTheme.style,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _deleteDeduction(
                                      widget.deduction.deductionId ?? 0),
                                  icon: const Icon(CupertinoIcons.trash),
                                  label: const Text('删除'),
                                  style: themeData.elevatedButtonTheme.style
                                      ?.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(
                                        themeData.colorScheme.error),
                                    foregroundColor: WidgetStatePropertyAll(
                                        themeData.colorScheme.onError),
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
