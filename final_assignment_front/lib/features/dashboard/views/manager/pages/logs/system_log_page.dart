import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/api/system_logs_controller_api.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/manager_record_table.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/page_auth_mixin.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
}

class SystemLogPage extends StatefulWidget {
  const SystemLogPage({super.key});

  @override
  State<SystemLogPage> createState() => _SystemLogPageState();
}

class _SystemLogPageState extends State<SystemLogPage> with PageAuthMixin {
  final SystemLogsControllerApi logApi = SystemLogsControllerApi();
  final ScrollController _scrollController = ScrollController();
  final ManagerDashboardController controller =
      Get.find<ManagerDashboardController>();

  Map<String, dynamic> _overviewData = {};
  List<LoginLog> _recentLoginLogs = [];
  List<OperationLog> _recentOperationLogs = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final roles = await requireRoles(
        (roles) => roles.contains('ADMIN'),
      );
      if (roles == null) return; // session expired, redirected to login
      _isAdmin = roles.isNotEmpty;
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
        return;
      }
      await logApi.initializeWithJwt();
      await _fetchSystemLogData(showLoader: false);
    } catch (e) {
      setState(() => _errorMessage = '页面没有准备好，请稍后重试。');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSystemLogData({bool showLoader = true}) async {
    if (!_isAdmin) return;
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      if (await ensureFreshJwt() == null) return;
      await logApi.initializeWithJwt();
      final overview = await logApi.getSystemLogsOverview();
      final loginLogs = await logApi.listRecentLoginLogs(limit: 20);
      final operationLogs = await logApi.listRecentOperationLogs(limit: 20);
      setState(() {
        _overviewData = overview;
        _recentLoginLogs = loginLogs;
        _recentOperationLogs = operationLogs;
        _errorMessage = '';
      });
    } catch (e) {
      developer.log('Failed to fetch system logs: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is AppException && e.code == 403) {
          _errorMessage = '您没有权限查看系统日志';
        } else {
          _errorMessage = '系统日志没有加载成功，请稍后重试。';
        }
      });
    } finally {
      if (showLoader) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchSystemLogData(showLoader: false);
  }

  String _formatOverviewLabel(String key) {
    final snake = key.replaceAll('_', ' ');
    return snake.replaceAllMapped(
      RegExp('(?<=[a-z])([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
  }

  Widget _buildWarningCard(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    final dark = themeData.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.45 : 0.58),
        ),
      ),
      child: Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: themeData.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildOverviewSection(ThemeData themeData) {
    return DashboardPanel(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统概览',
            style: themeData.textTheme.titleMedium?.copyWith(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (_overviewData.isEmpty)
            _buildEmptySection(themeData, '暂无系统概览数据')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _overviewData.entries.map((entry) {
                final value = entry.value;
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeData.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatOverviewLabel(entry.key),
                        style: themeData.textTheme.bodySmall?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value?.toString() ?? '0',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          color: themeData.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(ThemeData themeData, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info,
            color: themeData.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLogsSection(ThemeData themeData) {
    return DashboardPanel(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近期登录日志',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_recentLoginLogs.isEmpty)
            _buildEmptySection(themeData, '暂无登录日志。刷新后会显示在这里。')
          else
            SizedBox(
              height: 420,
              child: ManagerRecordTable(
                rows: [
                  for (final log in _recentLoginLogs)
                    ManagerTableRow(
                      cells: [
                        ManagerTableCell(label: '用户', value: log.username ?? '未知用户'),
                        ManagerTableCell(label: '结果', value: log.loginResult ?? '未知'),
                        ManagerTableCell(label: '时间', value: formatDateTime(log.loginTime)),
                        ManagerTableCell(label: 'IP', value: log.loginIp ?? '未知'),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationLogsSection(ThemeData themeData) {
    return DashboardPanel(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近期操作日志',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_recentOperationLogs.isEmpty)
            _buildEmptySection(themeData, '暂无操作日志。刷新后会显示在这里。')
          else
            SizedBox(
              height: 420,
              child: ManagerRecordTable(
                rows: [
                  for (final log in _recentOperationLogs)
                    ManagerTableRow(
                      cells: [
                        ManagerTableCell(
                          label: '用户',
                          value: log.username ?? log.realName ?? '未知用户',
                        ),
                        ManagerTableCell(
                          label: '模块',
                          value: log.operationModule ?? log.operationFunction ?? '未知模块',
                        ),
                        ManagerTableCell(label: '结果', value: log.operationResult ?? '未知'),
                        ManagerTableCell(label: '时间', value: formatDateTime(log.operationTime)),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData themeData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: themeData.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_errorMessage.contains('权限') || _errorMessage.contains('登录'))
              ElevatedButton(
                onPressed: () => NavigationHelper.offAllNamed(Routes.login),
                child: const Text('重新登录'),
              )
            else
              ElevatedButton(
                onPressed: _initialize,
                child: const Text('重试'),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasData() {
    return _overviewData.isNotEmpty ||
        _recentLoginLogs.isNotEmpty ||
        _recentOperationLogs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final showBlockingError = _errorMessage.isNotEmpty && !_hasData();
      return DashboardPageTemplate(
        theme: themeData,
        title: '系统日志',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onRefresh: _fetchSystemLogData,
        onThemeToggle: controller.toggleBodyTheme,
        body: _isLoading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: themeData.colorScheme.primary,
                  radius: 16.0,
                ),
              )
            : showBlockingError
                ? _buildErrorView(themeData)
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: themeData.colorScheme.primary,
                    backgroundColor: themeData.colorScheme.surfaceContainer,
                    child: CupertinoScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          if (_errorMessage.isNotEmpty && _hasData()) ...[
                            _buildWarningCard(themeData),
                            const SizedBox(height: 16),
                          ],
                          _buildOverviewSection(themeData),
                          const SizedBox(height: 16),
                          _buildLoginLogsSection(themeData),
                          const SizedBox(height: 16),
                          _buildOperationLogsSection(themeData),
                        ],
                      ),
                    ),
                  ),
      );
    });
  }
}
