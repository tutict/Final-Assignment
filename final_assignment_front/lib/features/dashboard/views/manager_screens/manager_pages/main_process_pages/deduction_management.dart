import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  final DeductionInformationControllerApi deductionApi = DeductionInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<DeductionInformation> _deductions = [];
  List<DeductionInformation> _filteredDeductions = [];
  String _searchType = 'handler';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final DashboardController controller = Get.find<DashboardController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      _applyFilters(_searchController.text);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadDeductions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() => _errorMessage = '登录已过期，请重新登录');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN' ||
          (decodedToken['roles'] is List && decodedToken['roles'].contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
        return;
      }
      await _loadDeductions(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeductions({bool reset = false, String? query}) async {
    if (!_isAdmin || (!_hasMore && !reset)) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _deductions.clear();
      _filteredDeductions.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      List<DeductionInformation> deductions = [];
      final searchQuery = query?.trim() ?? '';
      if (searchQuery.isEmpty && _startTime == null && _endTime == null) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
        deductions.sort((a, b) {
          final aTime = a.deductionTime ?? DateTime(1970);
          final bTime = b.deductionTime ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
      } else if (_searchType == 'handler' && searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsByHandlerGet(handler: searchQuery) ?? [];
      } else if (_searchType == 'timeRange' && _startTime != null && _endTime != null) {
        deductions = await deductionApi.apiDeductionsByTimeRangeGet(
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.add(const Duration(days: 1)).toIso8601String(),
        ) ??
            [];
      }

      setState(() {
        _deductions.addAll(deductions);
        _hasMore = deductions.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredDeductions.isEmpty) {
          _errorMessage = searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
              ? '未找到符合条件的扣分记录'
              : '暂无扣分记录';
        }
        if (reset) _currentPage = 1;
        _currentPage++;
      });

      // Clear cache to ensure fresh data
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      await http.post(
        Uri.parse('http://localhost:8081/api/cache/clear'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
    } catch (e) {
      print('Load Deductions Error: $e');
      setState(() {
        if (e is ApiException && e.code == 404) {
          _deductions.clear();
          _filteredDeductions.clear();
          _errorMessage = '未找到符合条件的扣分记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(AppPages.login);
        } else {
          _errorMessage = '获取扣分记录失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredDeductions = _deductions.where((deduction) {
        final handler = (deduction.handler ?? '').toLowerCase();
        final deductionTime = deduction.deductionTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty && _searchType == 'handler') {
          matchesQuery = handler.contains(searchQuery);
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && deductionTime != null) {
          matchesDateRange = deductionTime.isAfter(_startTime!) &&
              deductionTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null && _endTime != null && deductionTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredDeductions.isEmpty && _deductions.isNotEmpty) {
        _errorMessage = '未找到符合条件的扣分记录';
      } else {
        _errorMessage = _filteredDeductions.isEmpty && _deductions.isEmpty ? '暂无扣分记录' : '';
      }
    });
  }

  void _createDeduction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDeductionPage()),
    ).then((value) {
      if (value == true) {
        _loadDeductions(reset: true);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.error : themeData.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';
    return DateFormat('yyyy-MM-dd HH:mm', 'zh_CN').format(dateTime);
  }

  Future<void> _selectDateRange(ThemeData themeData) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startTime != null && _endTime != null
          ? DateTimeRange(start: _startTime!, end: _endTime!)
          : null,
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: themeData.copyWith(
            colorScheme: themeData.colorScheme.copyWith(
              primary: themeData.colorScheme.primary,
              onPrimary: themeData.colorScheme.onPrimary,
              surface: themeData.colorScheme.surfaceContainer,
            ),
            dialogBackgroundColor: themeData.colorScheme.surfaceContainer,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked.start;
        _endTime = picked.end;
        _searchType = 'timeRange';
        _searchController.clear();
      });
      await _loadDeductions(reset: true);
    }
  }

  Widget _buildNoDataWidget(ThemeData themeData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : '暂无扣分记录',
            style: themeData.textTheme.titleMedium?.copyWith(
              color: themeData.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_errorMessage.contains('未授权'))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed(AppPages.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('重新登录'),
              ),
            ),
          if (_errorMessage.isNotEmpty && !_errorMessage.contains('未授权'))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () => _loadDeductions(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('重试'),
              ),
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
            '扣分管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.add, size: 24),
                color: themeData.colorScheme.onPrimaryContainer,
                onPressed: _createDeduction,
                tooltip: '添加扣分记录',
              ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              color: themeData.colorScheme.onPrimaryContainer,
              onPressed: _isLoading ? null : () => _loadDeductions(reset: true),
              tooltip: '刷新列表',
            ),
            IconButton(
              icon: Icon(
                themeData.brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
                size: 24,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadDeductions(reset: true),
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty || _searchType != 'handler') {
                                return const Iterable<String>.empty();
                              }
                              return _deductions
                                  .map((d) => d.handler ?? '')
                                  .where((s) =>
                                  s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _searchController.text = selection;
                              _loadDeductions(reset: true, query: selection);
                            },
                            fieldViewBuilder: (context, textEditingController, focusNode,
                                onFieldSubmitted) {
                              textEditingController.text = _searchController.text;
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: TextStyle(color: themeData.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: _searchType == 'handler' ? '按处理人搜索' : '选择时间范围',
                                  hintStyle: TextStyle(
                                      color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                                  prefixIcon:
                                  Icon(Icons.search, color: themeData.colorScheme.onSurfaceVariant),
                                  suffixIcon: textEditingController.text.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: themeData.colorScheme.onSurfaceVariant),
                                    onPressed: () {
                                      textEditingController.clear();
                                      _searchController.clear();
                                      _loadDeductions(reset: true);
                                    },
                                  )
                                      : null,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: themeData.colorScheme.outline)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: themeData.colorScheme.primary, width: 1.5)),
                                  filled: true,
                                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                                ),
                                onSubmitted: (value) => _loadDeductions(reset: true, query: value),
                                enabled: _searchType == 'handler',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        DropdownButton<String>(
                          value: _searchType,
                          items: const [
                            DropdownMenuItem(value: 'handler', child: Text('处理人')),
                            DropdownMenuItem(value: 'timeRange', child: Text('时间范围')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchType = value!;
                              _searchController.clear();
                              _startTime = null;
                              _endTime = null;
                              _loadDeductions(reset: true);
                            });
                          },
                          style: TextStyle(color: themeData.colorScheme.onSurface),
                          icon: Icon(Icons.arrow_drop_down, color: themeData.colorScheme.primary),
                          underline: Container(),
                        ),
                        if (_searchType == 'timeRange')
                          IconButton(
                            icon: Icon(Icons.date_range, color: themeData.colorScheme.primary),
                            onPressed: () => _selectDateRange(themeData),
                            tooltip: '选择日期范围',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: _isLoading && _currentPage == 1
                      ? Center(
                      child: CircularProgressIndicator(color: themeData.colorScheme.primary))
                      : _errorMessage.isNotEmpty && _filteredDeductions.isEmpty
                      ? _buildNoDataWidget(themeData)
                      : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          _scrollController.position.extentAfter < 200 &&
                          !_isLoading &&
                          _hasMore) {
                        _loadDeductions();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredDeductions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredDeductions.length && _hasMore) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: themeData.colorScheme.primary));
                        }
                        final deduction = _filteredDeductions[index];
                        return Card(
                          elevation: 3,
                          color: themeData.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            title: Text(
                              '扣分: ${deduction.deductedPoints ?? 0}',
                              style: themeData.textTheme.titleMedium?.copyWith(
                                color: themeData.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '处理人: ${deduction.handler ?? '未知'} | 时间: ${formatDateTime(deduction.deductionTime)} | 违法ID: ${deduction.offenseId ?? '无'}',
                              style: themeData.textTheme.bodyMedium?.copyWith(
                                color: themeData.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: _isAdmin
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      size: 18,
                                      color: themeData.colorScheme.primary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditDeductionPage(
                                            deduction: deduction),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        _loadDeductions(reset: true);
                                      }
                                    });
                                  },
                                  tooltip: '编辑',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      size: 18,
                                      color: themeData.colorScheme.error),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: const Text('确定要删除此扣分记录吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await deductionApi
                                            .apiDeductionsDeductionIdDelete(
                                            deductionId:
                                            deduction.deductionId!);
                                        _showSnackBar('删除扣分记录成功');
                                        _loadDeductions(reset: true);
                                      } catch (e) {
                                        _showSnackBar(
                                            '删除失败: ${_formatErrorMessage(e)}',
                                            isError: true);
                                      }
                                    }
                                  },
                                  tooltip: '删除',
                                ),
                              ],
                            )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditDeductionPage(deduction: deduction),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _loadDeductions(reset: true);
                                }
                              });
                            },
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
  final DeductionInformationControllerApi deductionApi = DeductionInformationControllerApi();
  final OffenseInformationControllerApi offenseApi = OffenseInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _deductedPointsController = TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _approverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int? _selectedOffenseId;
  List<Map<String, dynamic>> _offenseSuggestions = [];
  final DashboardController controller = Get.find<DashboardController>();

  String generateIdempotencyKey() => const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await _fetchOffenseSuggestions();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _approverController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchOffenseSuggestions() async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final offenses = await offenseApi.apiOffensesGet() ?? [];
      setState(() {
        _offenseSuggestions = offenses
            .map((offense) => {
          'offenseId': offense.offenseId,
          'description':
          '违法ID: ${offense.offenseId} | 扣分: ${offense.deductedPoints ?? 0} | 时间: ${formatDateTime(offense.offenseTime)}'
        })
            .toList();
      });
    } catch (e) {
      _showSnackBar('获取违法记录失败: $e', isError: true);
    }
  }

  Future<void> _onOffenseSelected(Map<String, dynamic> selection) async {
    try {
      final offenseId = selection['offenseId'] as int?;
      if (offenseId == null) return;
      final offenses = await offenseApi.apiOffensesGet() ?? [];
      final selectedOffense = offenses.firstWhere((o) => o.offenseId == offenseId);
      setState(() {
        _selectedOffenseId = offenseId;
        _deductedPointsController.text = (selectedOffense.deductedPoints ?? 0).toString();
        _dateController.text = formatDateTime(selectedOffense.offenseTime);
      });
    } catch (e) {
      _showSnackBar('选择违法记录失败: $e', isError: true);
      setState(() {
        _selectedOffenseId = null;
        _deductedPointsController.clear();
        _dateController.clear();
      });
    }
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('请先选择一个违法记录', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final deduction = DeductionInformation(
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse('${_dateController.text}T00:00:00.000'),
        handler: _handlerController.text.trim().isEmpty ? null : _handlerController.text.trim(),
        approver: _approverController.text.trim().isEmpty ? null : _approverController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        idempotencyKey: idempotencyKey,
        offenseId: _selectedOffenseId,
      );
      await deductionApi.apiDeductionsPost(
          deductionInformation: deduction, idempotencyKey: idempotencyKey);
      _showSnackBar('创建扣分记录成功！');

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      await http.post(
        Uri.parse('http://localhost:8081/api/cache/clear'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

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
            color: isError ? themeData.colorScheme.error : themeData.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('yyyy-MM-dd', 'zh_CN').format(dateTime);
  }

  Future<void> _pickDate() async {
    final themeData = controller.currentBodyTheme.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.parse('${_dateController.text}T00:00:00.000')
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: themeData.copyWith(
            colorScheme: themeData.colorScheme.copyWith(
              primary: themeData.colorScheme.primary,
              onPrimary: themeData.colorScheme.onPrimary,
              surface: themeData.colorScheme.surfaceContainer,
            ),
            dialogBackgroundColor: themeData.colorScheme.surfaceContainer,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = formatDateTime(picked);
      });
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      ThemeData themeData, {
        TextInputType? keyboardType,
        bool readOnly = false,
        VoidCallback? onTap,
        bool required = false,
        int? maxLength,
        String? Function(String?)? validator,
        bool isAutocomplete = false,
        List<Map<String, dynamic>>? suggestions,
        Future<void> Function(Map<String, dynamic>)? onSelected,
      }) {
    if (isAutocomplete && suggestions != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return suggestions;
            }
            return suggestions.where((option) => option['description']
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (Map<String, dynamic> option) => option['description'],
          onSelected: (Map<String, dynamic> selection) {
            onSelected?.call(selection);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                helperText: '请选择违法记录',
                helperStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () {
                    textEditingController.clear();
                    setState(() {
                      _selectedOffenseId = null;
                      _deductedPointsController.clear();
                      _dateController.clear();
                    });
                  },
                )
                    : null,
              ),
              validator: validator ?? (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return '$label不能为空';
                }
                return null;
              },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: themeData.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option['description'],
                          style: TextStyle(color: themeData.colorScheme.onSurface),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == '处理人' || label == '审批人'
              ? '请输入${label}姓名（选填）'
              : label == '扣分分数 *'
              ? '请输入扣分点数'
              : label == '扣分时间 *'
              ? '请选择扣分日期'
              : null,
          helperStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: label == '扣分时间 *'
              ? Icon(Icons.calendar_today, size: 18, color: themeData.colorScheme.primary)
              : controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
            onPressed: () => controller.clear(),
          )
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: label == '扣分时间 *' ? true : readOnly,
        onTap: label == '扣分时间 *' ? _pickDate : onTap,
        maxLength: maxLength,
        validator: validator ?? (value) {
          final trimmedValue = value?.trim() ?? '';
          if (required && trimmedValue.isEmpty) return '$label不能为空';
          if (label == '扣分分数 *') {
            final points = int.tryParse(trimmedValue);
            if (points == null) return '扣分必须是数字';
            if (points < 0) return '扣分不能为负数';
            if (points > 12) return '扣分不能超过12分';
          }
          if (label == '处理人' || label == '审批人') {
            if (trimmedValue.length > 100) return '$label姓名不能超过100个字符';
          }
          if (label == '备注' && trimmedValue.length > 255) return '备注不能超过255个字符';
          if (label == '扣分时间 *') {
            final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
            if (date == null) return '无效的日期格式';
            if (date.isAfter(DateTime.now())) return '扣分日期不能晚于当前日期';
          }
          return null;
        },
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
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: themeData.colorScheme.primary))
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    color: themeData.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            '违法记录 *',
                            TextEditingController(),
                            themeData,
                            required: true,
                            isAutocomplete: true,
                            suggestions: _offenseSuggestions,
                            onSelected: _onOffenseSelected,
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
                            maxLength: 100,
                          ),
                          _buildTextField(
                            '审批人',
                            _approverController,
                            themeData,
                            maxLength: 100,
                          ),
                          _buildTextField(
                            '备注',
                            _remarksController,
                            themeData,
                            maxLength: 255,
                          ),
                          _buildTextField(
                            '扣分时间 *',
                            _dateController,
                            themeData,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                      textStyle:
                      themeData.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
  final DeductionInformationControllerApi deductionApi = DeductionInformationControllerApi();
  final OffenseInformationControllerApi offenseApi = OffenseInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _deductedPointsController = TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _approverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int? _selectedOffenseId;
  List<Map<String, dynamic>> _offenseSuggestions = [];
  final DashboardController controller = Get.find<DashboardController>();

  String generateIdempotencyKey() => const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _initialize();
    _populateFields();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await _fetchOffenseSuggestions();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    _deductedPointsController.text = widget.deduction.deductedPoints?.toString() ?? '';
    _handlerController.text = widget.deduction.handler ?? '';
    _approverController.text = widget.deduction.approver ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text = formatDateTime(widget.deduction.deductionTime);
    _selectedOffenseId = widget.deduction.offenseId;
  }

  Future<void> _fetchOffenseSuggestions() async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final offenses = await offenseApi.apiOffensesGet() ?? [];
      setState(() {
        _offenseSuggestions = offenses
            .map((offense) => {
          'offenseId': offense.offenseId,
          'description':
          '违法ID: ${offense.offenseId} | 扣分: ${offense.deductedPoints ?? 0} | 时间: ${formatDateTime(offense.offenseTime)}'
        })
            .toList();
      });
    } catch (e) {
      _showSnackBar('获取违法记录失败: $e', isError: true);
    }
  }

  Future<void> _onOffenseSelected(Map<String, dynamic> selection) async {
    try {
      final offenseId = selection['offenseId'] as int?;
      if (offenseId == null) return;
      final offenses = await offenseApi.apiOffensesGet() ?? [];
      final selectedOffense = offenses.firstWhere((o) => o.offenseId == offenseId);
      setState(() {
        _selectedOffenseId = offenseId;
        _deductedPointsController.text = (selectedOffense.deductedPoints ?? 0).toString();
        _dateController.text = formatDateTime(selectedOffense.offenseTime);
      });
    } catch (e) {
      _showSnackBar('选择违法记录失败: $e', isError: true);
      setState(() {
        _selectedOffenseId = null;
        _deductedPointsController.clear();
        _dateController.clear();
      });
    }
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('请先选择一个违法记录', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        deductedPoints: int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse('${_dateController.text}T00:00:00.000'),
        handler: _handlerController.text.trim().isEmpty ? null : _handlerController.text.trim(),
        approver: _approverController.text.trim().isEmpty ? null : _approverController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        idempotencyKey: idempotencyKey,
        offenseId: _selectedOffenseId,
      );
      await deductionApi.apiDeductionsDeductionIdPut(
          deductionId: widget.deduction.deductionId!,
          deductionInformation: deduction,
          idempotencyKey: idempotencyKey);
      _showSnackBar('更新扣分记录成功！');

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      await http.post(
        Uri.parse('http://localhost:8081/api/cache/clear'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

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
            color: isError ? themeData.colorScheme.error : themeData.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('yyyy-MM-dd', 'zh_CN').format(dateTime);
  }

  Future<void> _pickDate() async {
    final themeData = controller.currentBodyTheme.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.parse('${_dateController.text}T00:00:00.000')
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: themeData.copyWith(
            colorScheme: themeData.colorScheme.copyWith(
              primary: themeData.colorScheme.primary,
              onPrimary: themeData.colorScheme.onPrimary,
              surface: themeData.colorScheme.surfaceContainer,
            ),
            dialogBackgroundColor: themeData.colorScheme.surfaceContainer,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = formatDateTime(picked);
      });
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      ThemeData themeData, {
        TextInputType? keyboardType,
        bool readOnly = false,
        VoidCallback? onTap,
        bool required = false,
        int? maxLength,
        String? Function(String?)? validator,
        bool isAutocomplete = false,
        List<Map<String, dynamic>>? suggestions,
        Future<void> Function(Map<String, dynamic>)? onSelected,
      }) {
    if (isAutocomplete && suggestions != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return suggestions;
            }
            return suggestions.where((option) => option['description']
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (Map<String, dynamic> option) => option['description'],
          onSelected: (Map<String, dynamic> selection) {
            onSelected?.call(selection);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                helperText: '请选择违法记录',
                helperStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () {
                    textEditingController.clear();
                    setState(() {
                      _selectedOffenseId = null;
                      _deductedPointsController.clear();
                      _dateController.clear();
                    });
                  },
                )
                    : null,
              ),
              validator: validator ?? (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return '$label不能为空';
                }
                return null;
              },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: themeData.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option['description'],
                          style: TextStyle(color: themeData.colorScheme.onSurface),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == '处理人' || label == '审批人'
              ? '请输入${label}姓名（选填）'
              : label == '扣分分数 *'
              ? '请输入扣分点数'
              : label == '扣分时间 *'
              ? '请选择扣分日期'
              : null,
          helperStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: label == '扣分时间 *'
              ? Icon(Icons.calendar_today, size: 18, color: themeData.colorScheme.primary)
              : controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
            onPressed: () => controller.clear(),
          )
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: label == '扣分时间 *' ? true : readOnly,
        onTap: label == '扣分时间 *' ? _pickDate : onTap,
        maxLength: maxLength,
        validator: validator ?? (value) {
          final trimmedValue = value?.trim() ?? '';
          if (required && trimmedValue.isEmpty) return '$label不能为空';
          if (label == '扣分分数 *') {
            final points = int.tryParse(trimmedValue);
            if (points == null) return '扣分必须是数字';
            if (points < 0) return '扣分不能为负数';
            if (points > 12) return '扣分不能超过12分';
          }
          if (label == '处理人' || label == '审批人') {
            if (trimmedValue.length > 100) return '$label姓名不能超过100个字符';
          }
          if (label == '备注' && trimmedValue.length > 255) return '备注不能超过255个字符';
          if (label == '扣分时间 *') {
            final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
            if (date == null) return '无效的日期格式';
            if (date.isAfter(DateTime.now())) return '扣分日期不能晚于当前日期';
          }
          return null;
        },
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
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: themeData.colorScheme.primary))
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    color: themeData.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            '违法记录 *',
                            TextEditingController(
                                text: _selectedOffenseId != null
                                    ? _offenseSuggestions
                                    .firstWhere(
                                      (o) => o['offenseId'] == _selectedOffenseId,
                                  orElse: () => {
                                    'description': '违法ID: $_selectedOffenseId'
                                  },
                                )['description']
                                    : ''),
                            themeData,
                            required: true,
                            isAutocomplete: true,
                            suggestions: _offenseSuggestions,
                            onSelected: _onOffenseSelected,
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
                            maxLength: 100,
                          ),
                          _buildTextField(
                            '审批人',
                            _approverController,
                            themeData,
                            maxLength: 100,
                          ),
                          _buildTextField(
                            '备注',
                            _remarksController,
                            themeData,
                            maxLength: 255,
                          ),
                          _buildTextField(
                            '扣分时间 *',
                            _dateController,
                            themeData,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                      textStyle:
                      themeData.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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