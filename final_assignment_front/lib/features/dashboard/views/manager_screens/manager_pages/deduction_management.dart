import 'dart:developer' as developer;
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

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
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _driverLicenseController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    deductionApi = DeductionInformationControllerApi();
    _loadDeductions();
  }

  @override
  void dispose() {
    _driverLicenseController.dispose();
    _handlerController.dispose();
    super.dispose();
  }

  Future<void> _loadDeductions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await deductionApi.initializeWithJwt();
      _deductionsFuture = deductionApi.apiDeductionsGet();
      await _deductionsFuture;
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

  Future<void> _searchDeductions(
      String type, String? query, DateTimeRange? dateRange) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await deductionApi.initializeWithJwt();
      if (type == 'license' && query != null && query.isNotEmpty) {
        final deduction =
            await deductionApi.apiDeductionsLicenseLicenseGet(license: query);
        _deductionsFuture = Future.value(deduction != null ? [deduction] : []);
      } else if (type == 'handler' && query != null && query.isNotEmpty) {
        _deductionsFuture =
            deductionApi.apiDeductionsHandlerHandlerGet(handler: query);
      } else if (type == 'timeRange' && dateRange != null) {
        _deductionsFuture = deductionApi.apiDeductionsTimeRangeGet(
          startTime: dateRange.start.toIso8601String(),
          endTime: dateRange.end.toIso8601String(),
        );
      } else {
        await _loadDeductions();
        return;
      }
      await _deductionsFuture;
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching deductions: $e');
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
      _showSuccessSnackBar('删除扣分记录成功！');
      _loadDeductions();
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  void _goToDetailPage(DeductionInformation deduction) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                DeductionDetailPage(deduction: deduction))).then((value) {
      if (value == true && mounted) _loadDeductions();
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
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
      });
      _searchDeductions('timeRange', null, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('扣分信息管理',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'license')
                    _searchDeductions(
                        'license', _driverLicenseController.text.trim(), null);
                  else if (value == 'handler')
                    _searchDeductions(
                        'handler', _handlerController.text.trim(), null);
                  else if (value == 'timeRange') _selectDateRange();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                      value: 'license', child: Text('按驾驶证号搜索')),
                  const PopupMenuItem<String>(
                      value: 'handler', child: Text('按处理人搜索')),
                  const PopupMenuItem<String>(
                      value: 'timeRange', child: Text('按时间范围搜索')),
                ],
                icon:
                    Icon(Icons.filter_list, color: theme.colorScheme.onPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddDeductionPage()))
                      .then((value) {
                    if (value == true && mounted) _loadDeductions();
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
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDeductions('license',
                          _driverLicenseController.text.trim(), null),
                      style: theme.elevatedButtonTheme.style,
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
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDeductions(
                          'handler', _handlerController.text.trim(), null),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (_errorMessage.isNotEmpty)
                  Expanded(
                      child: Center(
                          child: Text(_errorMessage,
                              style: theme.textTheme.bodyLarge)))
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
                              child: Text('加载扣分信息失败: ${snapshot.error}',
                                  style: theme.textTheme.bodyLarge));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('暂无扣分记录',
                                  style: theme.textTheme.bodyLarge));
                        } else {
                          final deductions = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadDeductions,
                            child: ListView.builder(
                              itemCount: deductions.length,
                              itemBuilder: (context, index) {
                                final deduction = deductions[index];
                                final points = deduction.deductedPoints ?? 0;
                                final time = deduction.deductionTime ?? '未知';
                                final handler = deduction.handler ?? '未记录';
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color: theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: ListTile(
                                    title: Text('扣分: $points 分',
                                        style: theme.textTheme.bodyLarge),
                                    subtitle: Text(
                                      '时间: $time\n处理人: $handler',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7)),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final did = deduction.deductionId;
                                        if (did != null) {
                                          if (value == 'edit')
                                            _goToDetailPage(deduction);
                                          else if (value == 'delete')
                                            _deleteDeduction(did);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                            value: 'edit', child: Text('编辑')),
                                        const PopupMenuItem<String>(
                                            value: 'delete', child: Text('删除')),
                                      ],
                                      icon: Icon(Icons.more_vert,
                                          color: theme.colorScheme.onSurface),
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
  final deductionApi = DeductionInformationControllerApi();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;

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
      final deduction = DeductionInformation(
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: _dateController.text.trim(),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
      );
      await deductionApi.apiDeductionsPost(
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSuccessSnackBar('创建扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('创建扣分记录失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加扣分信息',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: _buildDeductionForm(context)),
      ),
    );
  }

  Widget _buildDeductionForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon: const Icon(Icons.drive_eta),
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
          controller: _deductedPointsController,
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: const Icon(Icons.score),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          decoration: InputDecoration(
            labelText: '处理人',
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
            labelText: '扣分时间',
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

/// 编辑扣分信息页面
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
    _dateController.text = widget.deduction.deductionTime ?? '';
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
      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: _dateController.text.trim(),
        handler: _handlerController.text.trim(),
        remarks: _remarksController.text.trim(),
      );
      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId?.toString() ?? '',
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSuccessSnackBar('更新扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('更新扣分记录失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑扣分信息',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: _buildDeductionForm(context)),
      ),
    );
  }

  Widget _buildDeductionForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: _driverLicenseNumberController,
          decoration: InputDecoration(
            labelText: '驾驶证号',
            prefixIcon: const Icon(Icons.drive_eta),
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
          controller: _deductedPointsController,
          decoration: InputDecoration(
            labelText: '扣分分数',
            prefixIcon: const Icon(Icons.score),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            labelStyle: theme.textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _handlerController,
          decoration: InputDecoration(
            labelText: '处理人',
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
            labelText: '扣分时间',
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
          style: theme.elevatedButtonTheme.style,
          child: const Text('保存'),
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

/// 扣分详情页面
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
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

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
      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: deductionId.toString(),
        deductionInformation: deduction,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSuccessSnackBar('更新扣分记录成功！');
      if (mounted) {
        setState(
            () => widget.deduction.remarks = _remarksController.text.trim());
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('更新失败: $e');
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
      _showSuccessSnackBar('扣分记录删除成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = widget.deduction.deductedPoints ?? 0;
    final time = widget.deduction.deductionTime ?? '未知';
    final handler = widget.deduction.handler ?? '未记录';

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('扣分详情',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditDeductionPage(
                              deduction: widget.deduction))).then((value) {
                    if (value == true && mounted) setState(() {});
                  });
                },
                tooltip: '编辑扣分',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    _deleteDeduction(widget.deduction.deductionId ?? 0),
                tooltip: '删除扣分',
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
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary)),
                          ),
                          maxLines: 3,
                          style: theme.textTheme.bodyMedium,
                          onSubmitted: (value) => _updateDeduction(
                            widget.deduction.deductionId ?? 0,
                            widget.deduction.copyWith(
                              remarks: value.trim(),
                              handler: widget.deduction.handler,
                              deductedPoints: widget.deduction.deductedPoints,
                              deductionTime: widget.deduction.deductionTime,
                              driverLicenseNumber:
                                  widget.deduction.driverLicenseNumber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            _deleteDeduction(widget.deduction.deductionId ?? 0),
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                        ),
                        child: const Text('删除扣分'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
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
}
