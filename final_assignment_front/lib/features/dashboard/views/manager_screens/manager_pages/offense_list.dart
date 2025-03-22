import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 格式化日期的全局方法
String formatDate(DateTime? date) {
  if (date == null) return '无';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPageState();
}

class _OffenseListPageState extends State<OffenseList> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  List<OffenseInformation> _offenseList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String? _currentUsername;
  String _searchType = 'driverName'; // 默认搜索类型为司机姓名
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('userName');
    final jwtToken = prefs.getString('jwtToken');
    if (_currentUsername == null || jwtToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录以查看违法信息';
      });
      return;
    }
    await offenseApi.initializeWithJwt();
    _fetchOffenses(reset: true);
  }

  Future<void> _fetchOffenses({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _offenseList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final offenses = await offenseApi.apiOffensesGet(
              page: _currentPage, size: _pageSize) ??
          [];
      setState(() {
        _offenseList.addAll(offenses);
        _isLoading = false;
        if (offenses.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取违法信息失败: $e';
      });
    }
  }

  Future<void> _loadMoreOffenses() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchOffenses();
  }

  Future<void> _searchOffenses(String query) async {
    if (query.isEmpty) {
      await _fetchOffenses(reset: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _hasMore = true;
      _offenseList.clear();
    });
    try {
      switch (_searchType) {
        case 'driverName':
          final offenses = await offenseApi.apiOffensesDriverNameGet(
                driverName: query,
                page: _currentPage,
                size: _pageSize,
              ) ??
              [];
          setState(() {
            _offenseList = offenses;
            _isLoading = false;
            if (offenses.length < _pageSize) _hasMore = false;
            if (_offenseList.isEmpty) _errorMessage = '未找到司机名为 $query 的违法信息';
          });
          break;
        case 'licensePlate':
          final offenses = await offenseApi.apiOffensesLicensePlateGet(
                licensePlate: query,
                page: _currentPage,
                size: _pageSize,
              ) ??
              [];
          setState(() {
            _offenseList = offenses;
            _isLoading = false;
            if (offenses.length < _pageSize) _hasMore = false;
            if (_offenseList.isEmpty) _errorMessage = '未找到车牌号为 $query 的违法信息';
          });
          break;
        case 'processStatus':
          final offenses = await offenseApi.apiOffensesProcessStateGet(
                processState: query,
                page: _currentPage,
                size: _pageSize,
              ) ??
              [];
          setState(() {
            _offenseList = offenses;
            _isLoading = false;
            if (offenses.length < _pageSize) _hasMore = false;
            if (_offenseList.isEmpty) _errorMessage = '未找到状态为 $query 的违法信息';
          });
          break;
        default:
          setState(() {
            _errorMessage = '无效的搜索类型';
            _isLoading = false;
          });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '搜索失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (picked != null && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _hasMore = true;
        _offenseList.clear();
      });
      try {
        final offenses = await offenseApi.apiOffensesTimeRangeGet(
              startTime: picked.start,
              endTime: picked.end,
              page: _currentPage,
              size: _pageSize,
            ) ??
            [];
        setState(() {
          _offenseList = offenses;
          _isLoading = false;
          if (offenses.length < _pageSize) _hasMore = false;
          if (_offenseList.isEmpty) _errorMessage = '未找到该时间范围内的违法信息';
        });
      } catch (e) {
        setState(() {
          _errorMessage = '按时间范围搜索失败：$e';
          _isLoading = false;
        });
      }
    }
  }

  void _createOffense() {
    Get.to(() => const AddOffensePage())?.then((value) {
      if (value == true && mounted) _fetchOffenses(reset: true);
    });
  }

  void _goToDetailPage(OffenseInformation offense) {
    Get.to(() => OffenseDetailPage(offense: offense))?.then((value) {
      if (value == true && mounted) _fetchOffenses(reset: true);
    });
  }

  Future<void> _deleteOffense(int offenseId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此违法信息吗？');
    if (!confirmed) return;

    try {
      await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
      _showSnackBar('删除违法信息成功！');
      _fetchOffenses(reset: true);
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
              '违法行为列表',
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
                  onTap: _createOffense,
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
                    child: _isLoading && _currentPage == 1
                        ? Center(
                            child: CupertinoActivityIndicator(
                              color: themeData.colorScheme.primary,
                              radius: 16.0,
                            ),
                          )
                        : _offenseList.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无违法信息',
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
                                  onRefresh: () => _fetchOffenses(reset: true),
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _offenseList.length +
                                        (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _offenseList.length &&
                                          _hasMore) {
                                        _loadMoreOffenses();
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(
                                              child:
                                                  CupertinoActivityIndicator()),
                                        );
                                      }
                                      final offense = _offenseList[index];
                                      return _buildOffenseCard(
                                          offense, themeData);
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
                controller: _searchController,
                style: TextStyle(color: themeData.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: _searchType == 'driverName'
                      ? '按司机姓名搜索'
                      : _searchType == 'licensePlate'
                          ? '按车牌号搜索'
                          : '按处理状态搜索',
                  labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                  prefixIcon:
                      Icon(Icons.search, color: themeData.colorScheme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: themeData.colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            _fetchOffenses(reset: true);
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
                onSubmitted: (value) => _searchOffenses(value),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _searchType,
              onChanged: (String? newValue) {
                setState(() {
                  _searchType = newValue!;
                  _searchController.clear();
                  _fetchOffenses(reset: true);
                });
              },
              items: <String>['driverName', 'licensePlate', 'processStatus']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'driverName'
                        ? '按司机姓名'
                        : value == 'licensePlate'
                            ? '按车牌号'
                            : '按状态',
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

  Widget _buildOffenseCard(OffenseInformation offense, ThemeData themeData) {
    return Card(
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '违法类型: ${offense.offenseType ?? "未知类型"}',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '车牌号: ${offense.licensePlate ?? "未知车牌"}\n状态: ${offense.processStatus ?? "未知状态"}\n时间: ${formatDate(offense.offenseTime)}',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _goToDetailPage(offense),
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
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _offenseTypeController = TextEditingController();
  final _offenseCodeController = TextEditingController();
  final _offenseLocationController = TextEditingController();
  final _offenseTimeController = TextEditingController();
  final _deductedPointsController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _processStatusController = TextEditingController();
  final _processResultController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    offenseApi.initializeWithJwt();
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

  Future<void> _submitOffense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      DateTime? offenseTime;
      if (_offenseTimeController.text.isNotEmpty) {
        offenseTime =
            DateTime.parse("${_offenseTimeController.text.trim()}T00:00:00");
      }

      final offense = OffenseInformation(
        offenseId: null,
        driverName: _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim(),
        offenseTime: offenseTime,
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()),
        fineAmount: num.tryParse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim(),
        processResult: _processResultController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await offenseApi.apiOffensesPost(
        offenseInformation: offense,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建违法行为记录成功！');
      if (mounted) Get.back(result: true);
    } catch (e) {
      _showSnackBar('创建违法行为记录失败: $e', isError: true);
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
        _offenseTimeController.text = formatDate(pickedDate);
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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
              '添加新违法行为',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
              onPressed: () => Get.back(),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            elevation: 1,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeData.colorScheme.primary,
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: _buildOffenseForm(themeData),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOffenseForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '司机姓名', Icons.person, _driverNameController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '车牌号', Icons.directions_car, _licensePlateController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法类型', Icons.warning, _offenseTypeController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(themeData, '违法代码', Icons.code, _offenseCodeController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法地点', Icons.location_on, _offenseLocationController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法时间', Icons.calendar_today, _offenseTimeController,
            readOnly: true, onTap: _pickDate),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '扣分', Icons.remove_circle, _deductedPointsController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(themeData, '罚款金额', Icons.money, _fineAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '处理状态', Icons.assignment, _processStatusController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '处理结果', Icons.check_circle, _processResultController),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitOffense,
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

  String generateIdempotencyKey() {
    // Replace with your actual implementation for generating an idempotency key
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class OffenseDetailPage extends StatefulWidget {
  final OffenseInformation offense;

  const OffenseDetailPage({super.key, required this.offense});

  @override
  State<OffenseDetailPage> createState() => _OffenseDetailPageState();
}

class _OffenseDetailPageState extends State<OffenseDetailPage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await offenseApi.initializeWithJwt();
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
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = roleData['roles'] as List<dynamic>;
        setState(() {
          _isEditable = roles.contains('ADMIN');
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

  Future<void> _deleteOffense(int offenseId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此违法信息吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
      _showSnackBar('删除违法信息成功！');
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
              '违法行为详情',
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
            trailing: _isEditable
                ? GestureDetector(
                    onTap: () => _showActions(widget.offense),
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
                        child: Card(
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
                                    '司机姓名',
                                    widget.offense.driverName ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '车牌号',
                                    widget.offense.licensePlate ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '违法类型',
                                    widget.offense.offenseType ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '违法代码',
                                    widget.offense.offenseCode ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '违法地点',
                                    widget.offense.offenseLocation ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '违法时间',
                                    formatDate(widget.offense.offenseTime),
                                    themeData),
                                _buildDetailRow(
                                    '扣分',
                                    widget.offense.deductedPoints?.toString() ??
                                        '未知',
                                    themeData),
                                _buildDetailRow(
                                    '罚款金额',
                                    widget.offense.fineAmount?.toString() ??
                                        '未知',
                                    themeData),
                                _buildDetailRow(
                                    '处理状态',
                                    widget.offense.processStatus ?? '未知',
                                    themeData),
                                _buildDetailRow(
                                    '处理结果',
                                    widget.offense.processResult ?? '未知',
                                    themeData),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  void _showActions(OffenseInformation offense) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => EditOffensePage(offense: offense))?.then((value) {
                if (value == true && mounted) Get.back(result: true);
              });
            },
            child: const Text('编辑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteOffense(offense.offenseId ?? 0);
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

class EditOffensePage extends StatefulWidget {
  final OffenseInformation offense;

  const EditOffensePage({super.key, required this.offense});

  @override
  State<EditOffensePage> createState() => _EditOffensePageState();
}

class _EditOffensePageState extends State<EditOffensePage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _offenseTypeController = TextEditingController();
  final _offenseCodeController = TextEditingController();
  final _offenseLocationController = TextEditingController();
  final _offenseTimeController = TextEditingController();
  final _deductedPointsController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _processStatusController = TextEditingController();
  final _processResultController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initializeFields();
    offenseApi.initializeWithJwt();
  }

  void _initializeFields() {
    _driverNameController.text = widget.offense.driverName ?? '';
    _licensePlateController.text = widget.offense.licensePlate ?? '';
    _offenseTypeController.text = widget.offense.offenseType ?? '';
    _offenseCodeController.text = widget.offense.offenseCode ?? '';
    _offenseLocationController.text = widget.offense.offenseLocation ?? '';
    _offenseTimeController.text = formatDate(widget.offense.offenseTime);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      DateTime? offenseTime;
      if (_offenseTimeController.text.isNotEmpty) {
        offenseTime =
            DateTime.parse("${_offenseTimeController.text.trim()}T00:00:00");
      }

      final updatedOffense = widget.offense.copyWith(
        driverName: _driverNameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        offenseType: _offenseTypeController.text.trim(),
        offenseCode: _offenseCodeController.text.trim(),
        offenseLocation: _offenseLocationController.text.trim(),
        offenseTime: offenseTime,
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()),
        fineAmount: num.tryParse(_fineAmountController.text.trim()),
        processStatus: _processStatusController.text.trim(),
        processResult: _processResultController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await offenseApi.apiOffensesOffenseIdPut(
        offenseId: widget.offense.offenseId ?? 0,
        offenseInformation: updatedOffense,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('更新违法行为记录成功！');
      if (mounted) Get.back(result: true);
    } catch (e) {
      _showSnackBar('更新违法行为记录失败: $e', isError: true);
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
      initialDate: widget.offense.offenseTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _offenseTimeController.text = formatDate(pickedDate);
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
              '编辑违法行为信息',
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
            child: Material(
              color: themeData.colorScheme.surface,
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
                          child: _buildOffenseForm(themeData),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOffenseForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '司机姓名', Icons.person, _driverNameController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '车牌号', Icons.directions_car, _licensePlateController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法类型', Icons.warning, _offenseTypeController,
            required: true),
        const SizedBox(height: 12),
        _buildTextField(themeData, '违法代码', Icons.code, _offenseCodeController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法地点', Icons.location_on, _offenseLocationController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '违法时间', Icons.calendar_today, _offenseTimeController,
            readOnly: true, onTap: _pickDate),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '扣分', Icons.remove_circle, _deductedPointsController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(themeData, '罚款金额', Icons.money, _fineAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '处理状态', Icons.assignment, _processStatusController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '处理结果', Icons.check_circle, _processResultController),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _updateOffense,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('保存'),
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
