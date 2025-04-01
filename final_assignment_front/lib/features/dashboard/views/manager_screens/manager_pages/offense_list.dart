import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
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
  final List<OffenseInformation> _offenseList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String? _currentUsername;
  String _searchType = 'driverName';
  DateTime? _startDate;
  DateTime? _endDate;

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
      _currentUsername = prefs.getString('userName');
      final jwtToken = prefs.getString('jwtToken');
      if (_currentUsername == null || jwtToken == null) {
        throw Exception('请先登录以查看违法信息');
      }
      await offenseApi.initializeWithJwt();
      await _fetchOffenses(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOffenses({bool reset = false, String? query}) async {
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

    final searchQuery = query?.trim() ?? '';
    try {
      List<OffenseInformation> offenses = [];
      if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
        offenses = await offenseApi.apiOffensesGet();
      } else if (_searchType == 'driverName' && searchQuery.isNotEmpty) {
        offenses = await offenseApi.apiOffensesByDriverNameGet(
          query: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_searchType == 'licensePlate' && searchQuery.isNotEmpty) {
        offenses = await offenseApi.apiOffensesByLicensePlateGet(
          query: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_searchType == 'offenseType' && searchQuery.isNotEmpty) {
        offenses = await offenseApi.apiOffensesByOffenseTypeGet(
          query: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_startDate != null && _endDate != null) {
        offenses = await offenseApi.apiOffensesTimeRangeGet(
          startTime: formatDate(_startDate),
          endTime: formatDate(_endDate),
        );
      }

      setState(() {
        _offenseList.addAll(offenses);
        if (offenses.length < _pageSize) _hasMore = false;
        if (_offenseList.isEmpty && _currentPage == 1) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startDate != null && _endDate != null)
                  ? '未找到符合条件的违法信息'
                  : '当前没有违法记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('404')) {
          _offenseList.clear();
          _errorMessage = '未找到符合条件的违法信息，可能 $_searchType "$searchQuery" 不存在';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取违法信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreOffenses() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchOffenses(query: _searchController.text);
  }

  Future<void> _refreshOffenses() async {
    _searchController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    await _fetchOffenses(reset: true);
  }

  Future<void> _searchOffenses() async {
    final query = _searchController.text.trim();
    await _fetchOffenses(reset: true, query: query);
  }

  void _createOffense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddOffensePage()),
    ).then((value) {
      if (value == true && mounted) _fetchOffenses(reset: true);
    });
  }

  void _goToDetailPage(OffenseInformation offense) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => OffenseDetailPage(offense: offense)),
    ).then((value) {
      if (value == true && mounted) _fetchOffenses(reset: true);
    });
  }

  Future<void> _deleteOffense(int offenseId) async {
    _showDeleteConfirmationDialog('删除', () async {
      setState(() => _isLoading = true);
      try {
        await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
        _showSnackBar('删除违法信息成功！');
        _fetchOffenses(reset: true);
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
            '您确定要$action此违法信息吗？此操作不可撤销。',
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
                    hintText: _searchType == 'driverName'
                        ? '搜索司机姓名'
                        : _searchType == 'licensePlate'
                            ? '搜索车牌号'
                            : '搜索违法类型',
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
                              _fetchOffenses(reset: true);
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
                  onSubmitted: (value) => _searchOffenses(),
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
                    _fetchOffenses(reset: true);
                  });
                },
                items: <String>['driverName', 'licensePlate', 'offenseType']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'driverName'
                          ? '按司机姓名'
                          : value == 'licensePlate'
                              ? '按车牌号'
                              : '按违法类型',
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
                      ? '违法时间范围: ${formatDate(_startDate)} 至 ${formatDate(_endDate)}'
                      : '选择违法时间范围',
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
                tooltip: '按违法时间范围搜索',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: '选择违法时间范围',
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
                    });
                    _searchOffenses();
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
                    _searchOffenses();
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
          title: Text('违法行为管理',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshOffenses,
                tooltip: '刷新列表'),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createOffense,
                tooltip: '添加新违法信息'),
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
          onRefresh: _refreshOffenses,
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
                        _loadMoreOffenses();
                      }
                      return false;
                    },
                    child: _isLoading && _currentPage == 1
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    themeData.colorScheme.primary)))
                        : _errorMessage.isNotEmpty && _offenseList.isEmpty
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
                                    _offenseList.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _offenseList.length &&
                                      _hasMore) {
                                    return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  }
                                  final offense = _offenseList[index];
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
                                        '违法类型: ${offense.offenseType ?? '未知类型'}',
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
                                          Text(
                                              '车牌号: ${offense.licensePlate ?? '未知车牌'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '司机姓名: ${offense.driverName ?? '未知司机'}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurfaceVariant)),
                                          Text(
                                              '状态: ${offense.processStatus ?? '无'}',
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
                                            icon: Icon(Icons.delete,
                                                size: 18,
                                                color: themeData
                                                    .colorScheme.error),
                                            onPressed: () => _deleteOffense(
                                                offense.offenseId ?? 0),
                                            tooltip: '删除违法信息',
                                          ),
                                          Icon(Icons.arrow_forward_ios,
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                              size: 18),
                                        ],
                                      ),
                                      onTap: () => _goToDetailPage(offense),
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
          onPressed: _createOffense,
          backgroundColor: themeData.colorScheme.primary,
          foregroundColor: themeData.colorScheme.onPrimary,
          tooltip: '添加新违法信息',
          child: const Icon(Icons.add),
        ),
      );
    });
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
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await offenseApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
      final offenseTime = _offenseTimeController.text.isEmpty
          ? null
          : DateTime.parse(
              "${_offenseTimeController.text.trim()}T00:00:00.000");

      final offensePayload = {
        'offenseId': null,
        'driverName': _driverNameController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'offenseType': _offenseTypeController.text.trim(),
        'offenseCode': _offenseCodeController.text.trim().isEmpty
            ? null
            : _offenseCodeController.text.trim(),
        'offenseLocation': _offenseLocationController.text.trim().isEmpty
            ? null
            : _offenseLocationController.text.trim(),
        'offenseTime': offenseTime?.toIso8601String(),
        'deductedPoints': _deductedPointsController.text.trim().isEmpty
            ? null
            : int.parse(_deductedPointsController.text.trim()),
        'fineAmount': _fineAmountController.text.trim().isEmpty
            ? null
            : num.parse(_fineAmountController.text.trim()),
        'processStatus': _processStatusController.text.trim().isEmpty
            ? null
            : _processStatusController.text.trim(),
        'processResult': _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
      };

      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/offenses?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(offensePayload),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create offense: ${response.statusCode} - ${response.body}');
      }

      _showSnackBar('创建违法行为记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建违法行为记录失败: $e', isError: true);
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
      setState(() => _offenseTimeController.text = formatDate(pickedDate));
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('添加新违法行为',
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
                                    '司机姓名', _driverNameController, themeData,
                                    required: true),
                                _buildTextField(
                                    '车牌号', _licensePlateController, themeData,
                                    required: true),
                                _buildTextField(
                                    '违法类型', _offenseTypeController, themeData,
                                    required: true),
                                _buildTextField(
                                    '违法代码', _offenseCodeController, themeData),
                                _buildTextField('违法地点',
                                    _offenseLocationController, themeData),
                                _buildTextField(
                                    '违法时间', _offenseTimeController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    '扣分', _deductedPointsController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true)),
                                _buildTextField('处理状态',
                                    _processStatusController, themeData),
                                _buildTextField('处理结果',
                                    _processResultController, themeData),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitOffense,
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
    setState(() => _isLoading = true);
    try {
      await offenseApi.initializeWithJwt();
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
      if (jwtToken == null) throw Exception('未登录，请重新登录');
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
        setState(() => _isEditable = roles.contains('ROLE_ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteOffense(int offenseId) async {
    setState(() => _isLoading = true);
    try {
      await offenseApi.apiOffensesOffenseIdDelete(offenseId: offenseId);
      _showSnackBar('删除违法信息成功！');
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

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('确认删除',
              style: themeData.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          content: Text('您确定要$action此违法信息吗？此操作不可撤销。',
              style: themeData.textTheme.bodyMedium
                  ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消',
                  style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
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
          title: Text('违法行为详情',
              style: themeData.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onPrimaryContainer)),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: _isEditable
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditOffensePage(offense: widget.offense)))
                          .then((value) {
                        if (value == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    },
                    tooltip: '编辑违法信息',
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: themeData.colorScheme.error),
                    onPressed: () => _showDeleteConfirmationDialog('删除',
                        () => _deleteOffense(widget.offense.offenseId ?? 0)),
                    tooltip: '删除违法信息',
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
                          _buildDetailRow('司机姓名',
                              widget.offense.driverName ?? '未知', themeData),
                          _buildDetailRow('车牌号',
                              widget.offense.licensePlate ?? '未知', themeData),
                          _buildDetailRow('违法类型',
                              widget.offense.offenseType ?? '未知', themeData),
                          _buildDetailRow('违法代码',
                              widget.offense.offenseCode ?? '无', themeData),
                          _buildDetailRow('违法地点',
                              widget.offense.offenseLocation ?? '无', themeData),
                          _buildDetailRow(
                              '违法时间',
                              formatDate(widget.offense.offenseTime),
                              themeData),
                          _buildDetailRow(
                              '扣分',
                              widget.offense.deductedPoints?.toString() ?? '无',
                              themeData),
                          _buildDetailRow(
                              '罚款金额',
                              widget.offense.fineAmount?.toString() ?? '无',
                              themeData),
                          _buildDetailRow('处理状态',
                              widget.offense.processStatus ?? '无', themeData),
                          _buildDetailRow('处理结果',
                              widget.offense.processResult ?? '无', themeData),
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
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await offenseApi.initializeWithJwt();
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
      final offenseTime = _offenseTimeController.text.isEmpty
          ? null
          : DateTime.parse(
              "${_offenseTimeController.text.trim()}T00:00:00.000");

      final offensePayload = {
        'offenseId': widget.offense.offenseId,
        'driverName': _driverNameController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'offenseType': _offenseTypeController.text.trim(),
        'offenseCode': _offenseCodeController.text.trim().isEmpty
            ? null
            : _offenseCodeController.text.trim(),
        'offenseLocation': _offenseLocationController.text.trim().isEmpty
            ? null
            : _offenseLocationController.text.trim(),
        'offenseTime': offenseTime?.toIso8601String(),
        'deductedPoints': _deductedPointsController.text.trim().isEmpty
            ? null
            : int.parse(_deductedPointsController.text.trim()),
        'fineAmount': _fineAmountController.text.trim().isEmpty
            ? null
            : num.parse(_fineAmountController.text.trim()),
        'processStatus': _processStatusController.text.trim().isEmpty
            ? null
            : _processStatusController.text.trim(),
        'processResult': _processResultController.text.trim().isEmpty
            ? null
            : _processResultController.text.trim(),
      };

      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/offenses/${widget.offense.offenseId}?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(offensePayload),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update offense: ${response.statusCode} - ${response.body}');
      }

      _showSnackBar('更新违法行为记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新违法行为记录失败: $e', isError: true);
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
      initialDate: widget.offense.offenseTime ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() => _offenseTimeController.text = formatDate(pickedDate));
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
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text('编辑违法行为信息',
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
                                    '司机姓名', _driverNameController, themeData,
                                    required: true),
                                _buildTextField(
                                    '车牌号', _licensePlateController, themeData,
                                    required: true),
                                _buildTextField(
                                    '违法类型', _offenseTypeController, themeData,
                                    required: true),
                                _buildTextField(
                                    '违法代码', _offenseCodeController, themeData),
                                _buildTextField('违法地点',
                                    _offenseLocationController, themeData),
                                _buildTextField(
                                    '违法时间', _offenseTimeController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    '扣分', _deductedPointsController, themeData,
                                    keyboardType: TextInputType.number),
                                _buildTextField(
                                    '罚款金额', _fineAmountController, themeData,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true)),
                                _buildTextField('处理状态',
                                    _processStatusController, themeData),
                                _buildTextField('处理结果',
                                    _processResultController, themeData),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateOffense,
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
