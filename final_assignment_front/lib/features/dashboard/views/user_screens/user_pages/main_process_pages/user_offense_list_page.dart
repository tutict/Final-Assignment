import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'dart:developer' as developer;

class UserOffenseListPage extends StatefulWidget {
  const UserOffenseListPage({super.key});

  @override
  State<UserOffenseListPage> createState() => _UserOffenseListPageState();
}

class _UserOffenseListPageState extends State<UserOffenseListPage> {
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final List<OffenseInformation> _offenses = [];
  List<OffenseInformation> _filteredOffenses = [];
  String _driverName = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _startTime;
  DateTime? _endTime;
  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await prefs.setString('jwtToken', jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          return false;
        }
        await offenseApi.initializeWithJwt();
      }
      setState(() {
        _driverName = decodedToken['driverName'] ?? decodedToken['sub'] ?? '';
      });
      if (_driverName.isEmpty) {
        // Fetch driverName from user profile if not in JWT
        final driverName = await _fetchDriverName(jwtToken);
        if (driverName == null) {
          setState(() => _errorMessage = '无法获取司机姓名，请联系管理员');
          return false;
        }
        setState(() => _driverName = driverName);
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<String?> _fetchDriverName(String jwtToken) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return userData['driverName'] as String?;
      }
      return null;
    } catch (e) {
      developer.log('Error fetching driver name: $e');
      return null;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await prefs.setString('jwtToken', newJwt);
        return newJwt;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      if (_driverName.isEmpty) {
        setState(() => _errorMessage = '无法获取司机姓名，请联系管理员');
        return;
      }
      await offenseApi.initializeWithJwt();
      await _loadOffenses(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOffenses({bool reset = false}) async {
    if (!_hasMore || _driverName.isEmpty) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _offenses.clear();
      _filteredOffenses.clear();
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
      final offenses = await offenseApi.apiOffensesByDriverNameGet(
        query: _driverName,
        page: _currentPage,
        size: _pageSize,
      );

      setState(() {
        _offenses.addAll(offenses);
        _hasMore = offenses.length == _pageSize;
        _applyFilters();
        if (_filteredOffenses.isEmpty) {
          _errorMessage = _startTime != null && _endTime != null
              ? '未找到符合时间范围的违法记录'
              : '暂无违法记录';
        }
        _currentPage++;
      });
      developer.log('Loaded offenses: ${_offenses.length}');
    } catch (e) {
      developer.log('Error fetching offenses: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is ApiException && e.code == 204) {
          _offenses.clear();
          _filteredOffenses.clear();
          _errorMessage = '未找到违法记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(AppPages.login);
        } else {
          _errorMessage = '获取违法记录失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _applyFilters() {
    setState(() {
      _filteredOffenses.clear();
      _filteredOffenses = _offenses.where((offense) {
        final offenseTime = offense.offenseTime;
        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && offenseTime != null) {
          matchesDateRange = offenseTime.isAfter(_startTime!) &&
              offenseTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            offenseTime == null) {
          matchesDateRange = false;
        }
        return matchesDateRange;
      }).toList();

      if (_filteredOffenses.isEmpty && _offenses.isNotEmpty) {
        _errorMessage = '未找到符合时间范围的违法记录';
      } else {
        _errorMessage =
            _filteredOffenses.isEmpty && _offenses.isEmpty ? '暂无违法记录' : '';
      }
    });
  }

  Future<void> _loadMoreOffenses() async {
    if (!_isLoading && _hasMore) {
      await _loadOffenses();
    }
  }

  Future<void> _refreshOffenses() async {
    setState(() {
      _offenses.clear();
      _filteredOffenses.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _startTime = null;
      _endTime = null;
    });
    await _loadOffenses(reset: true);
  }

  void _goToDetailPage(OffenseInformation offense) {
    Get.to(() => UserOffenseDetailPage(offense: offense));
  }

  Widget _buildTimeRangeFilter(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _startTime != null && _endTime != null
                  ? '时间范围: ${formatDateTime(_startTime)} 至 ${formatDateTime(_endTime)}'
                  : '选择时间范围',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: _startTime != null && _endTime != null
                    ? themeData.colorScheme.onSurface
                    : themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.date_range, color: themeData.colorScheme.primary),
            tooltip: '按时间范围筛选',
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
                builder: (context, child) => Theme(
                  data: themeData.copyWith(
                    colorScheme: themeData.colorScheme.copyWith(
                      primary: themeData.colorScheme.primary,
                      onPrimary: themeData.colorScheme.onPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: themeData.colorScheme.primary,
                      ),
                    ),
                  ),
                  child: child!,
                ),
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
          if (_startTime != null && _endTime != null)
            IconButton(
              icon: Icon(Icons.clear,
                  color: themeData.colorScheme.onSurfaceVariant),
              tooltip: '清除时间范围',
              onPressed: () {
                setState(() {
                  _startTime = null;
                  _endTime = null;
                });
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '无';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '我的违法记录',
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
              icon: Icon(Icons.refresh,
                  color: themeData.colorScheme.onPrimaryContainer, size: 24),
              onPressed: _refreshOffenses,
              tooltip: '刷新列表',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            IconButton(
              icon: Icon(
                themeData.brightness == Brightness.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshOffenses,
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildTimeRangeFilter(themeData),
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
                                  themeData.colorScheme.primary),
                            ),
                          )
                        : _errorMessage.isNotEmpty && _filteredOffenses.isEmpty
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
                                        _errorMessage.contains('登录'))
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
                                itemCount: _filteredOffenses.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredOffenses.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final offense = _filteredOffenses[index];
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
                                        '违法类型: ${offense.offenseType ?? '未知'}',
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
                                            '车牌号: ${offense.licensePlate ?? '无'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '扣分: ${offense.deductedPoints ?? 0} 分',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '时间: ${formatDateTime(offense.offenseTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                        size: 18,
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
      );
    });
  }
}

class UserOffenseDetailPage extends StatelessWidget {
  final OffenseInformation offense;

  const UserOffenseDetailPage({super.key, required this.offense});

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未提供';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '违法详情',
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
                    _buildDetailRow('违法ID',
                        offense.offenseId?.toString() ?? '未提供', themeData),
                    _buildDetailRow(
                        '车牌号', offense.licensePlate ?? '无', themeData),
                    _buildDetailRow(
                        '驾驶员姓名', offense.driverName ?? '无', themeData),
                    _buildDetailRow(
                        '违法类型', offense.offenseType ?? '未知', themeData),
                    _buildDetailRow(
                        '违法代码', offense.offenseCode ?? '无', themeData),
                    _buildDetailRow(
                        '扣分', '${offense.deductedPoints ?? 0} 分', themeData),
                    _buildDetailRow(
                        '罚款金额', '${offense.fineAmount ?? 0} 元', themeData),
                    _buildDetailRow(
                        '违法时间', formatDateTime(offense.offenseTime), themeData),
                    _buildDetailRow(
                        '违法地点', offense.offenseLocation ?? '未提供', themeData),
                    _buildDetailRow(
                        '处理状态', offense.processStatus ?? '无', themeData),
                    _buildDetailRow(
                        '处理结果', offense.processResult ?? '无', themeData),
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
