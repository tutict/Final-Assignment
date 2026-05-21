// user_offense_list_page.dart
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_business_page_chrome.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/shared/widgets/index.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

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
  final TextEditingController _searchController = TextEditingController();
  String _driverName = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  int? _driverId;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isUser = false;
  String _errorMessage = '';
  DateTime? _startTime;
  DateTime? _endTime;
  late ScrollController _scrollController;

  final UserDashboardController? dashboardController =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

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

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      var decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        final refreshed = await Get.find<AuthService>().refreshJwtToken();
        jwtToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed || jwtToken == null || JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        decodedToken = JwtDecoder.decode(jwtToken);
      }
      final roles = _extractRoleCodes(decodedToken['roles']);
      _isUser = roles.contains('USER');
      if (!_isUser) {
        setState(() => _errorMessage = '权限不足：仅用户可访问此页面');
        return false;
      }
      final profile = await Get.find<UserProfileService>().getProfile();
      _driverId = profile.driverId;
      _driverName = profile.driverName ?? prefs.getString('driverName') ?? '';
      if (_driverId == null) {
        setState(() => _errorMessage = '您的账户尚未关联司机档案');
        return false;
      }
      _driverName = _driverName.isNotEmpty ? _driverName : profile.username;
      return true;
    } catch (e) {
      developer.log('JWT validation error: $e');
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  List<String> _extractRoleCodes(Object? value) {
    final rawRoles = value is Iterable
        ? value.map((role) => role.toString())
        : value?.toString().split(',') ?? const Iterable<String>.empty();
    return rawRoles
        .map((role) => role.replaceFirst('ROLE_', '').trim().toUpperCase())
        .where((role) => role.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        return;
      }
      if (_driverId == null) {
        setState(() => _errorMessage = '您的账户尚未关联司机档案');
        return;
      }
      await offenseApi.initializeWithJwt();
      await _loadOffenses(reset: true);
    } catch (e) {
      developer.log('Initialization error: $e');
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOffenses({bool reset = false}) async {
    if (!_hasMore || _driverId == null) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _offenses.clear();
      _filteredOffenses.clear();
      _searchController.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        NavigationHelper.offAllNamed(Routes.login);
        return;
      }
      final offenses = await offenseApi.listOffensesByDriver(
        driverId: _driverId!,
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
              : _searchController.text.isNotEmpty
                  ? '未找到符合搜索条件的违法记录'
                  : '暂无违法记录';
        }
        _currentPage++;
      });
      developer.log('Loaded offenses: ${_offenses.length}');
    } catch (e) {
      developer.log('Error fetching offenses: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is AppException && e.code == 204) {
          _offenses.clear();
          _filteredOffenses.clear();
          _errorMessage = '未找到违法记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '您没有权限查看违法记录';
        } else {
          _errorMessage = '获取违法记录失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppException) {
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
        bool matchesSearch = true;
        if (_searchController.text.isNotEmpty) {
          final searchText = _searchController.text.toLowerCase();
          matchesSearch =
              (offense.offenseType?.toLowerCase().contains(searchText) ??
                      false) ||
                  (offense.offenseCode?.toLowerCase().contains(searchText) ??
                      false);
        }
        return matchesDateRange && matchesSearch;
      }).toList();

      if (_filteredOffenses.isEmpty && _offenses.isNotEmpty) {
        _errorMessage = _startTime != null && _endTime != null
            ? '未找到符合时间范围的违法记录'
            : _searchController.text.isNotEmpty
                ? '未找到符合搜索条件的违法记录'
                : '暂无违法记录';
      } else {
        _errorMessage =
            _filteredOffenses.isEmpty && _offenses.isEmpty ? '暂无违法记录' : '';
      }
    });
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (_driverId == null) return [];
      final offenses = await offenseApi.listOffensesByDriver(
        driverId: _driverId!,
        page: 1,
        size: 10,
      );
      final suggestions = <String>{};
      for (var offense in offenses) {
        if (offense.offenseType != null &&
            offense.offenseType!.toLowerCase().contains(prefix.toLowerCase())) {
          suggestions.add(offense.offenseType!);
        }
        if (offense.offenseCode != null &&
            offense.offenseCode!.toLowerCase().contains(prefix.toLowerCase())) {
          suggestions.add(offense.offenseCode!);
        }
      }
      return suggestions.toList();
    } catch (e) {
      developer.log('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
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
      _searchController.clear();
    });
    await _loadOffenses(reset: true);
  }

  void _goToDetailPage(OffenseInformation offense) {
    Get.to(() => UserOffenseDetailPage(offense: offense));
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return SearchFilterBar(
      controller: _searchController,
      wrapInCard: true,
      cardElevation: 2,
      cardBorderRadius: 8,
      cardColor: themeData.colorScheme.surfaceContainer,
      cardPadding: const EdgeInsets.all(8),
      inputBorderRadius: 8,
      hintText: '搜索违法类型或代码',
      suggestions: _fetchAutocompleteSuggestions,
      showDateRange: true,
      startDate: _startTime,
      endDate: _endTime,
      dateRangeTextBuilder: (start, end) =>
          '时间范围: ${formatDateTime(start)} 至 ${formatDateTime(end)}',
      dateRangePlaceholder: '选择时间范围',
      dateRangeTooltip: '按时间范围筛选',
      dateRangeHelpText: '选择时间范围',
      onDateRangeChanged: (range) {
        setState(() {
          _startTime = range?.start;
          _endTime = range?.end;
        });
        _applyFilters();
      },
      onSearch: (_) => _applyFilters(),
      onChanged: (value) {
        if (value.isEmpty) {
          _applyFilters();
        }
      },
      onClear: () {
        _searchController.clear();
        _applyFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = dashboardController != null
          ? dashboardController!.currentBodyTheme.value
          : Theme.of(context);
      if (!_isUser) {
        return DashboardPageTemplate(
          theme: themeData,
          title: '违法详情',
          pageType: DashboardPageType.user,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const UserBusinessPageHeader(
                  title: '违法详情',
                  subtitle: '按违法类型、代码和时间范围查询个人违法记录。',
                  icon: Icons.info_rounded,
                  badge: '待处理',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: UserBusinessStatusPanel(
                    message: _errorMessage,
                    kind: UserBusinessStatusKind.error,
                    actionLabel: userBusinessMessageNeedsLogin(_errorMessage)
                        ? '重新登录'
                        : null,
                    onAction: userBusinessMessageNeedsLogin(_errorMessage)
                        ? () => NavigationHelper.offAllNamed(Routes.login)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return DashboardPageTemplate(
        theme: themeData,
        title: '违法详情',
        pageType: DashboardPageType.user,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: RefreshIndicator(
          onRefresh: _refreshOffenses,
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                UserBusinessPageHeader(
                  title: '违法详情',
                  subtitle: '按违法类型、代码和时间范围查询个人违法记录。',
                  icon: Icons.info_rounded,
                  badge: '${_filteredOffenses.length} 条记录',
                ),
                const SizedBox(height: 12),
                _buildSearchBar(themeData),
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
                                child: UserBusinessStatusPanel(
                                  message: _errorMessage,
                                  kind: _errorMessage.contains('暂无') ||
                                          _errorMessage.contains('未找到')
                                      ? UserBusinessStatusKind.empty
                                      : UserBusinessStatusKind.error,
                                  actionLabel: userBusinessMessageNeedsLogin(
                                          _errorMessage)
                                      ? '重新登录'
                                      : null,
                                  onAction: userBusinessMessageNeedsLogin(
                                          _errorMessage)
                                      ? () => NavigationHelper.offAllNamed(
                                          Routes.login)
                                      : null,
                                ),
                              )
                            : CupertinoScrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _scrollController,
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
                                    return UserBusinessRecordCard(
                                      icon: Icons.info_outline_rounded,
                                      title: offense.offenseType ?? '未知违法类型',
                                      badge: '${offense.deductedPoints ?? 0} 分',
                                      details: [
                                        '车牌号：${offense.licensePlate ?? '无'}',
                                        '违法代码：${offense.offenseCode ?? '无'}',
                                        '违法时间：${formatDateTime(offense.offenseTime)}',
                                      ],
                                      onTap: () => _goToDetailPage(offense),
                                    );
                                  },
                                ),
                              ),
                  ),
                )
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
  final UserDashboardController? dashboardController;

  UserOffenseDetailPage({super.key, required this.offense})
      : dashboardController = Get.isRegistered<UserDashboardController>()
            ? Get.find<UserDashboardController>()
            : null;

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
    return Obx(() {
      final themeData = dashboardController != null
          ? dashboardController!.currentBodyTheme.value
          : Theme.of(context);
      return DashboardPageTemplate(
        theme: themeData,
        title: '违法详情',
        pageType: DashboardPageType.user,
        body: Card(
          elevation: 3,
          color: themeData.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    '违法ID', offense.offenseId?.toString() ?? '未提供', themeData),
                _buildDetailRow('车牌号', offense.licensePlate ?? '无', themeData),
                _buildDetailRow('驾驶员姓名', offense.driverName ?? '无', themeData),
                _buildDetailRow('违法类型', offense.offenseType ?? '未知', themeData),
                _buildDetailRow('违法代码', offense.offenseCode ?? '无', themeData),
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
      );
    });
  }
}
