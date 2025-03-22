import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final offenses =
          await offenseApi.apiOffensesGet(page: _currentPage, size: _pageSize);
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
              driverName: query, page: _currentPage, size: _pageSize);
          setState(() {
            _offenseList = offenses;
            _isLoading = false;
            if (offenses.length < _pageSize) _hasMore = false;
            if (_offenseList.isEmpty) _errorMessage = '未找到司机名为 $query 的违法信息';
          });
          break;
        case 'licensePlate':
          final offenses = await offenseApi.apiOffensesLicensePlateGet(
              licensePlate: query, page: _currentPage, size: _pageSize);
          setState(() {
            _offenseList = offenses;
            _isLoading = false;
            if (offenses.length < _pageSize) _hasMore = false;
            if (_offenseList.isEmpty) _errorMessage = '未找到车牌号为 $query 的违法信息';
          });
          break;
        case 'processStatus':
          final offenses = await offenseApi.apiOffensesProcessStateGet(
              processState: query, page: _currentPage, size: _pageSize);
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
        );
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
              controller: _searchController,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: _searchType == 'driverName'
                    ? '搜索司机姓名'
                    : _searchType == 'licensePlate'
                        ? '搜索车牌号'
                        : '搜索处理状态',
                hintStyle: TextStyle(
                    color: themeData.colorScheme.onSurface.withOpacity(0.6)),
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
        title: Text('违法行为列表',
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
            onPressed: _createOffense,
            tooltip: '添加新违法行为',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchOffenses(reset: true),
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
                      : _offenseList.isEmpty
                          ? Center(
                              child: Text('暂无违法信息',
                                  style:
                                      themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  )))
                          : ListView.builder(
                              itemCount:
                                  _offenseList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _offenseList.length && _hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final offense = _offenseList[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 3,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    title: Text(
                                      '违法类型: ${offense.offenseType ?? '未知类型'}',
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
                                        Text(
                                            '车牌号: ${offense.licensePlate ?? '未知车牌'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            )),
                                        Text(
                                            '状态: ${offense.processStatus ?? '未知状态'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            )),
                                        Text(
                                            '时间: ${formatDate(offense.offenseTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            )),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _goToDetailPage(offense);
                                        } else if (value == 'delete') {
                                          _deleteOffense(offense.offenseId!);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                            value: 'edit', child: Text('编辑')),
                                        const PopupMenuItem<String>(
                                            value: 'delete', child: Text('删除')),
                                      ],
                                      icon: Icon(Icons.more_vert,
                                          color: themeData
                                              .colorScheme.onSurfaceVariant),
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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
        offenseTime = DateTime.parse(_offenseTimeController.text.trim());
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _offenseTimeController.text = formatDate(pickedDate);
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
          '添加新违法行为',
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
                              _buildTextField(
                                  '处理状态', _processStatusController, themeData),
                              _buildTextField(
                                  '处理结果', _processResultController, themeData),
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
  final bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    offenseApi.initializeWithJwt();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
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
          _isEditable = roles.contains('ADMIN');
        });
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载权限失败: $e';
      });
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
          '违法行为详情',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EditOffensePage(offense: widget.offense)),
                    ).then((value) {
                      if (value == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  tooltip: '编辑违法信息',
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
                        _buildDetailRow('司机姓名',
                            widget.offense.driverName ?? '未知', themeData),
                        _buildDetailRow('车牌号',
                            widget.offense.licensePlate ?? '未知', themeData),
                        _buildDetailRow('违法类型',
                            widget.offense.offenseType ?? '未知', themeData),
                        _buildDetailRow('违法代码',
                            widget.offense.offenseCode ?? '未知', themeData),
                        _buildDetailRow('违法地点',
                            widget.offense.offenseLocation ?? '未知', themeData),
                        _buildDetailRow('违法时间',
                            formatDate(widget.offense.offenseTime), themeData),
                        _buildDetailRow(
                            '扣分',
                            widget.offense.deductedPoints?.toString() ?? '未知',
                            themeData),
                        _buildDetailRow(
                            '罚款金额',
                            widget.offense.fineAmount?.toString() ?? '未知',
                            themeData),
                        _buildDetailRow('处理状态',
                            widget.offense.processStatus ?? '未知', themeData),
                        _buildDetailRow('处理结果',
                            widget.offense.processResult ?? '未知', themeData),
                      ],
                    ),
                  ),
                ),
              ),
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

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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
        offenseTime = DateTime.parse(_offenseTimeController.text.trim());
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
        offenseId: widget.offense.offenseId!,
        offenseInformation: updatedOffense,
        idempotencyKey: idempotencyKey,
      );

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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _offenseTimeController.text = formatDate(pickedDate);
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
          '编辑违法行为信息',
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
                              _buildTextField(
                                  '处理状态', _processStatusController, themeData),
                              _buildTextField(
                                  '处理结果', _processResultController, themeData),
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
  }
}
