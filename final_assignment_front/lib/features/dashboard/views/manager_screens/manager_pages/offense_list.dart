import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPageState();
}

class _OffenseListPageState extends State<OffenseList> {
  late OffenseInformationControllerApi offenseApi;
  late Future<List<OffenseInformation>> _offensesFuture;
  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    offenseApi = OffenseInformationControllerApi();
    _loadOffenses();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _loadOffenses({
    String? driverName,
    String? licensePlate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await offenseApi.initializeWithJwt();
      if (driverName != null && driverName.isNotEmpty) {
        _offensesFuture = offenseApi.apiOffensesDriverNameDriverNameGet(
            driverName: driverName);
      } else if (licensePlate != null && licensePlate.isNotEmpty) {
        _offensesFuture = offenseApi.apiOffensesLicensePlateLicensePlateGet(
            licensePlate: licensePlate);
      } else if (startTime != null && endTime != null) {
        _offensesFuture = offenseApi.apiOffensesTimeRangeGet(
          startTime: startTime.toIso8601String(),
          endTime: endTime.toIso8601String(),
        );
      } else {
        _offensesFuture = offenseApi.apiOffensesGet();
      }
      await _offensesFuture;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('获取违法行为信息失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '获取违法行为信息失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _deleteOffense(int? offenseId) async {
    if (offenseId == null) return;
    try {
      await offenseApi.initializeWithJwt();
      await offenseApi.apiOffensesOffenseIdDelete(
          offenseId: offenseId.toString());
      _showSuccessSnackBar('删除违法信息成功！');
      _loadOffenses();
    } catch (e) {
      _showErrorSnackBar('删除违法信息失败: $e');
    }
  }

  void _searchOffensesByDriverName(String driverName) {
    _loadOffenses(driverName: driverName);
  }

  void _searchOffensesByLicensePlate(String licensePlate) {
    _loadOffenses(licensePlate: licensePlate);
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
      _loadOffenses(startTime: picked.start, endTime: picked.end);
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

  void _goToDetailPage(OffenseInformation offense) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OffenseDetailPage(offense: offense)))
        .then((value) {
      if (value == true && mounted) _loadOffenses();
    });
  }

  // Helper method to format DateTime to a readable string
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知时间';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Theme(
        data: controller?.currentBodyTheme.value ?? theme,
        child: Scaffold(
          appBar: AppBar(
            title: Text('违法行为列表',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDateRange,
                tooltip: '按时间范围搜索',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddOffensePage()))
                      .then((value) {
                    if (value == true && mounted) _loadOffenses();
                  });
                },
                tooltip: '添加新违法行为',
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
                        controller: _driverNameController,
                        decoration: InputDecoration(
                          labelText: '按司机姓名搜索',
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
                        onSubmitted: (value) =>
                            _searchOffensesByDriverName(value.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchOffensesByDriverName(
                          _driverNameController.text.trim()),
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
                        controller: _licensePlateController,
                        decoration: InputDecoration(
                          labelText: '按车牌号搜索',
                          prefixIcon: const Icon(Icons.directions_car),
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
                        onSubmitted: (value) =>
                            _searchOffensesByLicensePlate(value.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchOffensesByLicensePlate(
                          _licensePlateController.text.trim()),
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
                    child: FutureBuilder<List<OffenseInformation>>(
                      future: _offensesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('加载违法行为时发生错误: ${snapshot.error}',
                                  style: theme.textTheme.bodyLarge));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('没有找到违法行为信息',
                                  style: theme.textTheme.bodyLarge));
                        } else {
                          final offenses = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: () => _loadOffenses(),
                            child: ListView.builder(
                              itemCount: offenses.length,
                              itemBuilder: (context, index) {
                                final offense = offenses[index];
                                final type = offense.offenseType ?? '未知类型';
                                final plate = offense.licensePlate ?? '未知车牌';
                                final status = offense.processStatus ?? '未知状态';
                                final time =
                                    _formatDateTime(offense.offenseTime);
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color: theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: ListTile(
                                    title: Text('违法类型: $type',
                                        style: theme.textTheme.bodyLarge),
                                    subtitle: Text(
                                        '车牌号: $plate\n处理状态: $status\n时间: $time',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withOpacity(0.7))),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (offense.offenseId != null) {
                                          if (value == 'edit')
                                            _goToDetailPage(offense);
                                          else if (value == 'delete')
                                            _deleteOffense(offense.offenseId);
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
                                    onTap: () => _goToDetailPage(offense),
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

class AddOffensePage extends StatefulWidget {
  const AddOffensePage({super.key});

  @override
  State<AddOffensePage> createState() => _AddOffensePageState();
}

class _AddOffensePageState extends State<AddOffensePage> {
  final offenseApi = OffenseInformationControllerApi();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _offenseTypeController = TextEditingController();
  final TextEditingController _offenseCodeController = TextEditingController();
  final TextEditingController _offenseLocationController =
      TextEditingController();
  final TextEditingController _offenseTimeController = TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _fineAmountController = TextEditingController();
  final TextEditingController _processStatusController =
      TextEditingController();
  final TextEditingController _processResultController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    _offenseTypeController.dispose();
    _offenseCodeController.dispose();
    _offenseLocationController.dispose();
    _offenseTimeController.dispose();
    _deductedPointsController.dispose();
    _fineAmountController.dispose();
    _processStatusController.dispose();
    _processResultController.dispose();
    super.dispose();
  }

  Future<void> _submitOffense() async {
    setState(() => _isLoading = true);
    try {
      await offenseApi.initializeWithJwt();

      // Parse the offense time from string to DateTime
      DateTime? offenseTime;
      if (_offenseTimeController.text.trim().isNotEmpty) {
        offenseTime = DateTime.parse(_offenseTimeController.text.trim());
      }

      final offense = OffenseInformation(
        offenseId: null,
        // Backend will assign
        driverName: _driverNameController.text.trim().isEmpty
            ? null
            : _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isEmpty
            ? null
            : _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim().isEmpty
            ? null
            : _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim().isEmpty
            ? null
            : _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim().isEmpty
            ? null
            : _offenseLocationController.text.trim(),
        offenseTime: offenseTime,
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()),
        fineAmount: num.tryParse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim().isEmpty
            ? null
            : _processStatusController.text.trim(),
        processResult: _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      debugPrint('AddOffensePage Payload: ${offense.toJson()}');

      await offenseApi.apiOffensesPost(
        offenseInformation: offense,
        idempotencyKey: offense.idempotencyKey!,
      );
      _showSuccessSnackBar('创建违法行为记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('创建违法行为记录失败: $e');
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

  Future<void> _selectDate() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
          primaryColor: Theme.of(context).colorScheme.primary,
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _offenseTimeController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加新违法行为',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: _buildOffenseForm(context)),
      ),
    );
  }

  Widget _buildOffenseForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: _driverNameController,
          decoration: _inputDecoration(theme, '司机姓名', Icons.person),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _licensePlateController,
          decoration: _inputDecoration(theme, '车牌号', Icons.directions_car),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseTypeController,
          decoration: _inputDecoration(theme, '违法类型', Icons.warning),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseCodeController,
          decoration: _inputDecoration(theme, '违法代码', Icons.code),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseLocationController,
          decoration: _inputDecoration(theme, '违法地点', Icons.location_on),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseTimeController,
          decoration: _inputDecoration(theme, '违法时间', Icons.date_range),
          readOnly: true,
          style: theme.textTheme.bodyMedium,
          onTap: _selectDate,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deductedPointsController,
          decoration: _inputDecoration(theme, '扣分', Icons.score),
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fineAmountController,
          decoration: _inputDecoration(theme, '罚款金额', Icons.money),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _processStatusController,
          decoration: _inputDecoration(theme, '处理状态', Icons.check_circle),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _processResultController,
          decoration: _inputDecoration(theme, '处理结果', Icons.gavel),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitOffense,
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

  InputDecoration _inputDecoration(
      ThemeData theme, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      labelStyle: theme.textTheme.bodyMedium,
      enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary)),
    );
  }
}

class OffenseDetailPage extends StatefulWidget {
  final OffenseInformation offense;

  const OffenseDetailPage({super.key, required this.offense});

  @override
  State<OffenseDetailPage> createState() => _OffenseDetailPageState();
}

class _OffenseDetailPageState extends State<OffenseDetailPage> {
  final offenseApi = OffenseInformationControllerApi();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _offenseTypeController = TextEditingController();
  final TextEditingController _offenseCodeController = TextEditingController();
  final TextEditingController _offenseLocationController =
      TextEditingController();
  final TextEditingController _offenseTimeController = TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _fineAmountController = TextEditingController();
  final TextEditingController _processStatusController =
      TextEditingController();
  final TextEditingController _processResultController =
      TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _driverNameController.text = widget.offense.driverName ?? '';
    _licensePlateController.text = widget.offense.licensePlate ?? '';
    _offenseTypeController.text = widget.offense.offenseType ?? '';
    _offenseCodeController.text = widget.offense.offenseCode ?? '';
    _offenseLocationController.text = widget.offense.offenseLocation ?? '';
    _offenseTimeController.text = widget.offense.offenseTime != null
        ? "${widget.offense.offenseTime!.year}-${widget.offense.offenseTime!.month.toString().padLeft(2, '0')}-${widget.offense.offenseTime!.day.toString().padLeft(2, '0')}"
        : '';
    _deductedPointsController.text =
        widget.offense.deductedPoints?.toString() ?? '';
    _fineAmountController.text = widget.offense.fineAmount?.toString() ?? '';
    _processStatusController.text = widget.offense.processStatus ?? '';
    _processResultController.text = widget.offense.processResult ?? '';
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _licensePlateController.dispose();
    _offenseTypeController.dispose();
    _offenseCodeController.dispose();
    _offenseLocationController.dispose();
    _offenseTimeController.dispose();
    _deductedPointsController.dispose();
    _fineAmountController.dispose();
    _processStatusController.dispose();
    _processResultController.dispose();
    super.dispose();
  }

  Future<void> _updateOffense() async {
    setState(() => _isLoading = true);
    try {
      await offenseApi.initializeWithJwt();

      // Parse the offense time from string to DateTime
      DateTime? offenseTime;
      if (_offenseTimeController.text.trim().isNotEmpty) {
        offenseTime = DateTime.parse(_offenseTimeController.text.trim());
      }

      final updatedOffense = widget.offense.copyWith(
        driverName: _driverNameController.text.trim().isEmpty
            ? null
            : _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isEmpty
            ? null
            : _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim().isEmpty
            ? null
            : _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim().isEmpty
            ? null
            : _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim().isEmpty
            ? null
            : _offenseLocationController.text.trim(),
        offenseTime: offenseTime,
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()),
        fineAmount: num.tryParse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim().isEmpty
            ? null
            : _processStatusController.text.trim(),
        processResult: _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      debugPrint('OffenseDetailPage Payload: ${updatedOffense.toJson()}');

      await offenseApi.apiOffensesOffenseIdPut(
        offenseId: widget.offense.offenseId.toString(),
        offenseInformation: updatedOffense,
        idempotencyKey: updatedOffense.idempotencyKey!,
      );
      _showSuccessSnackBar('更新违法行为记录成功！');
      if (mounted) {
        setState(() => _isEditing = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('更新违法行为记录失败: $e');
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

  // Helper method to format DateTime to a readable string
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知时间';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.isRegistered<UserDashboardController>()
        ? Get.find<UserDashboardController>()
        : null;

    return Obx(
      () => Theme(
        data: controller?.currentBodyTheme.value ?? theme,
        child: Scaffold(
          appBar: AppBar(
            title: Text('违法行为详细信息',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              if (!_isEditing && widget.offense.offenseId != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: '编辑此记录',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: _isEditing
                        ? _buildEditForm(context)
                        : _buildDetailView(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('司机姓名', widget.offense.driverName ?? '未知', theme),
        _buildDetailRow('车牌号', widget.offense.licensePlate ?? '未知', theme),
        _buildDetailRow('违法类型', widget.offense.offenseType ?? '未知', theme),
        _buildDetailRow('违法代码', widget.offense.offenseCode ?? '未知', theme),
        _buildDetailRow('违法地点', widget.offense.offenseLocation ?? '未知', theme),
        _buildDetailRow(
            '违法时间', _formatDateTime(widget.offense.offenseTime), theme),
        _buildDetailRow(
            '扣分', widget.offense.deductedPoints?.toString() ?? '未知', theme),
        _buildDetailRow(
            '罚款金额', widget.offense.fineAmount?.toString() ?? '未知', theme),
        _buildDetailRow('处理状态', widget.offense.processStatus ?? '未知', theme),
        _buildDetailRow('处理结果', widget.offense.processResult ?? '未知', theme),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: _driverNameController,
          decoration: _inputDecoration(theme, '司机姓名', Icons.person),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _licensePlateController,
          decoration: _inputDecoration(theme, '车牌号', Icons.directions_car),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseTypeController,
          decoration: _inputDecoration(theme, '违法类型', Icons.warning),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseCodeController,
          decoration: _inputDecoration(theme, '违法代码', Icons.code),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseLocationController,
          decoration: _inputDecoration(theme, '违法地点', Icons.location_on),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _offenseTimeController,
          decoration: _inputDecoration(theme, '违法时间', Icons.date_range),
          readOnly: true,
          style: theme.textTheme.bodyMedium,
          onTap: _selectDate,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deductedPointsController,
          decoration: _inputDecoration(theme, '扣分', Icons.score),
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fineAmountController,
          decoration: _inputDecoration(theme, '罚款金额', Icons.money),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _processStatusController,
          decoration: _inputDecoration(theme, '处理状态', Icons.check_circle),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _processResultController,
          decoration: _inputDecoration(theme, '处理结果', Icons.gavel),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _updateOffense,
          style: theme.elevatedButtonTheme.style,
          child: const Text('保存'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _isEditing = false),
          style: theme.elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all(
                theme.colorScheme.onSurface.withOpacity(0.2)),
            foregroundColor:
                MaterialStateProperty.all(theme.colorScheme.onSurface),
          ),
          child: const Text('取消'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      ThemeData theme, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      labelStyle: theme.textTheme.bodyMedium,
      enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary)),
    );
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.offense.offenseTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
          primaryColor: Theme.of(context).colorScheme.primary,
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _offenseTimeController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
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
