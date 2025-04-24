import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/operation_log_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class OperationLogPage extends StatefulWidget {
  const OperationLogPage({super.key});

  @override
  State<OperationLogPage> createState() => _OperationLogPageState();
}

class _OperationLogPageState extends State<OperationLogPage> {
  final TextEditingController _searchController = TextEditingController();
  final OperationLogControllerApi logApi = OperationLogControllerApi();
  final RoleManagementControllerApi roleApi = RoleManagementControllerApi();
  final List<OperationLog> _logList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchType = 'userId'; // Default search type
  String? _currentUsername;
  bool _isAdmin = false;
  DateTimeRange? _selectedDateRange;

  final DashboardController controller =
      Get.find<DashboardController>();

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
      final decodedToken = JwtDecoder.decode(jwtToken);
      _currentUsername = decodedToken['sub'] ?? '';
      if (_currentUsername!.isEmpty) throw Exception('JWT 中未找到用户名');
      debugPrint('Current username from JWT: $_currentUsername');

      await logApi.initializeWithJwt();
      await roleApi.initializeWithJwt();
      await _fetchLogs(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      if (_isAdmin) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs({bool reset = false, String? query}) async {
    if (!_isAdmin) return;
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _logList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    debugPrint(
        'Fetching logs with query: $searchQuery, page: $_currentPage, searchType: $_searchType, dateRange: $_selectedDateRange');

    try {
      List<OperationLog> logs = [];
      if (_selectedDateRange != null) {
        final startTime = _selectedDateRange!.start.toIso8601String();
        final endTime = _selectedDateRange!.end.toIso8601String();
        debugPrint('Fetching logs by time range: $startTime to $endTime');
        logs = await logApi.apiOperationLogsTimeRangeGet(
          startTime: startTime,
          endTime: endTime,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (searchQuery.isEmpty) {
        debugPrint('Fetching all logs for page: $_currentPage');
        logs = await logApi.apiOperationLogsGet(
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_searchType == 'userId') {
        debugPrint('Fetching logs by userId: $searchQuery');
        logs = await logApi.apiOperationLogsUserIdUserIdGet(
          userId: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      } else if (_searchType == 'operationResult') {
        debugPrint('Fetching logs by operationResult: $searchQuery');
        logs = await logApi.apiOperationLogsResultResultGet(
          result: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
      }

      debugPrint('Logs fetched: ${logs.map((l) => l.toJson()).toList()}');
      setState(() {
        _logList.addAll(logs);
        if (logs.length < _pageSize) _hasMore = false;
        if (_logList.isEmpty && _currentPage == 1) {
          _errorMessage = searchQuery.isNotEmpty || _selectedDateRange != null
              ? '未找到符合条件的日志'
              : '当前没有日志记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('404')) {
          _logList.clear();
          _errorMessage = '未找到符合条件的日志';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取日志失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (_searchType == 'userId') {
        debugPrint('Fetching userId suggestions with prefix: $prefix');
        return ['1', '2', '3']; // Placeholder: Replace with actual API
      } else {
        debugPrint('Fetching operationResult suggestions with prefix: $prefix');
        return ['SUCCESS', 'FAILURE', 'PENDING']; // Placeholder
      }
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _loadMoreLogs() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchLogs(query: _searchController.text);
  }

  Future<void> _refreshLogs() async {
    _searchController.clear();
    _selectedDateRange = null;
    await _fetchLogs(reset: true);
  }

  Future<void> _searchLogs() async {
    final query = _searchController.text.trim();
    await _fetchLogs(reset: true, query: query);
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final themeData = controller.currentBodyTheme.value;
        return Theme(
          data: ThemeData(
            colorScheme: themeData.colorScheme,
            dialogBackgroundColor: themeData.colorScheme.surfaceContainer,
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _selectedDateRange = range;
        _searchController.clear();
      });
      await _fetchLogs(reset: true);
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

  Future<void> _showCreateLogDialog() async {
    final userIdController = TextEditingController();
    final operationContentController = TextEditingController();
    final operationResultController = TextEditingController();
    final remarksController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = const Uuid().v4();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          title: Text('创建操作日志', style: themeData.textTheme.titleLarge),
          backgroundColor: themeData.colorScheme.surfaceContainer,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userIdController,
                    decoration: InputDecoration(
                      labelText: '用户ID',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return '用户ID不能为空';
                      if (int.tryParse(value) == null) return '用户ID必须是数字';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: operationContentController,
                    decoration: InputDecoration(
                      labelText: '操作内容',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? '操作内容不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: operationResultController,
                    decoration: InputDecoration(
                      labelText: '操作结果',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value!.isEmpty ? '操作结果不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final newLog = OperationLog(
                      userId: int.parse(userIdController.text),
                      operationContent: operationContentController.text,
                      operationResult: operationResultController.text,
                      remarks: remarksController.text.isEmpty
                          ? null
                          : remarksController.text,
                      idempotencyKey: idempotencyKey,
                    );
                    await logApi.apiOperationLogsPost(
                      operationLog: newLog,
                      idempotencyKey: idempotencyKey,
                    );
                    _showSnackBar('日志创建成功');
                    Navigator.pop(context);
                    await _refreshLogs();
                  } catch (e) {
                    _showSnackBar('创建日志失败: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
              ),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditLogDialog(OperationLog log) async {
    final userIdController =
        TextEditingController(text: log.userId?.toString());
    final operationContentController =
        TextEditingController(text: log.operationContent);
    final operationResultController =
        TextEditingController(text: log.operationResult);
    final remarksController = TextEditingController(text: log.remarks);
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = const Uuid().v4();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          title: Text('编辑操作日志', style: themeData.textTheme.titleLarge),
          backgroundColor: themeData.colorScheme.surfaceContainer,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userIdController,
                    decoration: InputDecoration(
                      labelText: '用户ID',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return '用户ID不能为空';
                      if (int.tryParse(value) == null) return '用户ID必须是数字';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: operationContentController,
                    decoration: InputDecoration(
                      labelText: '操作内容',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? '操作内容不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: operationResultController,
                    decoration: InputDecoration(
                      labelText: '操作结果',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value!.isEmpty ? '操作结果不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updatedLog = OperationLog(
                      logId: log.logId,
                      userId: int.parse(userIdController.text),
                      operationContent: operationContentController.text,
                      operationResult: operationResultController.text,
                      operationTime: log.operationTime,
                      operationIpAddress: log.operationIpAddress,
                      remarks: remarksController.text.isEmpty
                          ? null
                          : remarksController.text,
                      idempotencyKey: idempotencyKey,
                    );
                    await logApi.apiOperationLogsLogIdPut(
                      logId: log.logId.toString(),
                      operationLog: updatedLog,
                      idempotencyKey: idempotencyKey,
                    );
                    _showSnackBar('日志更新成功');
                    Navigator.pop(context);
                    await _refreshLogs();
                  } catch (e) {
                    _showSnackBar('更新日志失败: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style: TextStyle(
                    color:
                        controller.currentBodyTheme.value.colorScheme.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.currentBodyTheme.value.colorScheme.error,
              foregroundColor:
                  controller.currentBodyTheme.value.colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await logApi.apiOperationLogsLogIdDelete(logId: logId);
        _showSnackBar('日志删除成功');
        await _refreshLogs();
      } catch (e) {
        _showSnackBar('删除日志失败: $e', isError: true);
      }
    }
  }

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return await _fetchAutocompleteSuggestions(
                    textEditingValue.text);
              },
              onSelected: (String selection) {
                _searchController.text = selection;
                _searchLogs();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                _searchController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: _searchType == 'userId' ? '搜索用户ID' : '搜索操作结果',
                    hintStyle: TextStyle(
                        color:
                            themeData.colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              controller.clear();
                              _searchController.clear();
                              _fetchLogs(reset: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                  ),
                  onSubmitted: (value) => _searchLogs(),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _searchType,
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
                _searchController.clear();
                _fetchLogs(reset: true);
              });
            },
            items: <String>['userId', 'operationResult']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value == 'userId' ? '按用户ID' : '按操作结果',
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
    final themeData = controller.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '操作日志',
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
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: '选择时间范围',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: '刷新日志列表',
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
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showCreateLogDialog,
              backgroundColor: themeData.colorScheme.primary,
              tooltip: '创建新日志',
              child: Icon(Icons.add, color: themeData.colorScheme.onPrimary),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshLogs,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isAdmin) _buildSearchField(themeData),
              const SizedBox(height: 12),
              if (_selectedDateRange != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '时间范围: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} 至 ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
                        style: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.clear,
                            color: themeData.colorScheme.error),
                        onPressed: () {
                          setState(() => _selectedDateRange = null);
                          _fetchLogs(reset: true);
                        },
                        tooltip: '清除时间范围',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        _hasMore &&
                        _isAdmin) {
                      _loadMoreLogs();
                    }
                    return false;
                  },
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  themeData.colorScheme.primary)))
                      : _errorMessage.isNotEmpty && _logList.isEmpty
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
                                  if (_errorMessage.contains('未授权') ||
                                      _errorMessage.contains('仅管理员'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pushReplacementNamed(
                                                context, '/login'),
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
                              itemCount: _logList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _logList.length && _hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final log = _logList[index];
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
                                      '日志ID: ${log.logId ?? '未知ID'}',
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
                                          '用户ID: ${log.userId ?? '未知用户ID'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '操作内容: ${log.operationContent ?? '无内容'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '操作结果: ${log.operationResult ?? '无结果'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '操作时间: ${log.operationTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(log.operationTime!) : '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'IP地址: ${log.operationIpAddress ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '备注: ${log.remarks ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: _isAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: themeData
                                                        .colorScheme.primary),
                                                onPressed: () =>
                                                    _showEditLogDialog(log),
                                                tooltip: '编辑日志',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: themeData
                                                        .colorScheme.error),
                                                onPressed: () => _deleteLog(
                                                    log.logId.toString()),
                                                tooltip: '删除日志',
                                              ),
                                            ],
                                          )
                                        : null,
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
  }
}
