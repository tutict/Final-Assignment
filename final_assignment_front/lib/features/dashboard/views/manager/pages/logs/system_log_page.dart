import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/api/system_logs_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '未提供';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
}

class SystemLogPage extends StatefulWidget {
  const SystemLogPage({super.key});

  @override
  State<SystemLogPage> createState() => _SystemLogPageState();
}

class _SystemLogPageState extends State<SystemLogPage> {
  final SystemLogsControllerApi logApi = SystemLogsControllerApi();
  final ScrollController _scrollController = ScrollController();
  final DashboardController controller = Get.find<DashboardController>();

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

  Future<bool> _validateJwtToken() async {
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null || JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        await logApi.initializeWithJwt();
      }
      return true;
    } catch (_) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
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
        final newJwt = jsonDecode(response.body)['jwtToken'] as String?;
        if (newJwt != null) {
          await AuthTokenStore.instance.setJwtToken(newJwt);
        }
        return newJwt;
      }
    } catch (e) {
      developer.log('Failed to refresh JWT token: $e',
          stackTrace: StackTrace.current);
    }
    return null;
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      await logApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) {
        await _fetchSystemLogData(showLoader: false);
      } else {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
      }
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      if (jwtToken == null) {
        setState(() => _isAdmin = false);
        return;
      }
      final decodedToken = JwtDecoder.decode(jwtToken);
      final roles = decodedToken['roles'] is List
          ? (decodedToken['roles'] as List).map((r) => r.toString()).toList()
          : decodedToken['roles'] is String
              ? [decodedToken['roles'].toString()]
              : [];
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        _errorMessage = '权限不足：仅管理员可访问此页面';
      }
    } catch (e) {
      setState(() => _errorMessage = '验证角色失败: $e');
      developer.log('Error checking user role: $e',
          stackTrace: StackTrace.current);
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
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      await logApi.initializeWithJwt();
      final overview = await logApi.apiSystemLogsOverviewGet();
      final loginLogs = await logApi.apiSystemLogsLoginRecentGet(limit: 20);
      final operationLogs =
          await logApi.apiSystemLogsOperationRecentGet(limit: 20);
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
        if (e is ApiException && e.code == 403) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(Routes.login);
        } else {
          _errorMessage = '加载系统日志失败: ${_formatErrorMessage(e)}';
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

  String _buildDeviceInfo(LoginLog log) {
    final parts = <String>[];
    if (log.browserType != null && log.browserType!.isNotEmpty) {
      parts.add(log.browserType!);
    }
    if (log.osType != null && log.osType!.isNotEmpty) {
      parts.add(log.osType!);
    }
    if (log.deviceType != null && log.deviceType!.isNotEmpty) {
      parts.add(log.deviceType!);
    }
    return parts.isEmpty ? '未知' : parts.join(' / ');
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到数据: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  Widget _buildWarningCard(ThemeData themeData) {
    return Card(
      color: themeData.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统概览',
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
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
                      borderRadius: BorderRadius.circular(12.0),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
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
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近期登录日志',
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentLoginLogs.isEmpty)
              _buildEmptySection(themeData, '暂无登录日志')
            else
              ..._recentLoginLogs.asMap().entries.map((entry) {
                return Column(
                  children: [
                    _buildLoginLogTile(entry.value, themeData),
                    if (entry.key != _recentLoginLogs.length - 1)
                      Divider(
                        height: 16,
                        color: themeData.colorScheme.outlineVariant,
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLogTile(LoginLog log, ThemeData themeData) {
    final subtitleStyle = themeData.textTheme.bodyMedium?.copyWith(
      color: themeData.colorScheme.onSurfaceVariant,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        log.username ?? '未知用户',
        style: themeData.textTheme.titleMedium?.copyWith(
          color: themeData.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('结果: ${log.loginResult ?? "未知"}', style: subtitleStyle),
          Text('IP: ${log.loginIp ?? "未知"}', style: subtitleStyle),
          if (log.loginLocation != null && log.loginLocation!.isNotEmpty)
            Text('位置: ${log.loginLocation}', style: subtitleStyle),
          Text('终端: ${_buildDeviceInfo(log)}', style: subtitleStyle),
          if (log.remarks != null && log.remarks!.isNotEmpty)
            Text('备注: ${log.remarks}', style: subtitleStyle),
        ],
      ),
      trailing: Text(
        formatDateTime(log.loginTime),
        style: themeData.textTheme.bodySmall?.copyWith(
          color: themeData.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildOperationLogsSection(ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近期操作日志',
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentOperationLogs.isEmpty)
              _buildEmptySection(themeData, '暂无操作日志')
            else
              ..._recentOperationLogs.asMap().entries.map((entry) {
                return Column(
                  children: [
                    _buildOperationLogTile(entry.value, themeData),
                    if (entry.key != _recentOperationLogs.length - 1)
                      Divider(
                        height: 16,
                        color: themeData.colorScheme.outlineVariant,
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationLogTile(OperationLog log, ThemeData themeData) {
    final subtitleStyle = themeData.textTheme.bodyMedium?.copyWith(
      color: themeData.colorScheme.onSurfaceVariant,
    );
    final userLabel =
        log.username ?? log.realName ?? log.userId?.toString() ?? '未知用户';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        log.operationModule ?? log.operationFunction ?? '未知模块',
        style: themeData.textTheme.titleMedium?.copyWith(
          color: themeData.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类型: ${log.operationType ?? "未知"}', style: subtitleStyle),
          Text('用户: $userLabel', style: subtitleStyle),
          Text('结果: ${log.operationResult ?? "未知"}', style: subtitleStyle),
          if (log.operationContent != null && log.operationContent!.isNotEmpty)
            Text(
              '内容: ${log.operationContent}',
              style: subtitleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text('IP: ${log.requestIp ?? "未知"}', style: subtitleStyle),
          if (log.remarks != null && log.remarks!.isNotEmpty)
            Text('备注: ${log.remarks}', style: subtitleStyle),
        ],
      ),
      trailing: Text(
        formatDateTime(log.operationTime),
        style: themeData.textTheme.bodySmall?.copyWith(
          color: themeData.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.right,
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
            ElevatedButton(
              onPressed: () => Get.offAllNamed(Routes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('重新登录'),
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
        body:
        _isLoading
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
                                backgroundColor:
                                    themeData.colorScheme.surfaceContainer,
                                child: CupertinoScrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  thickness: 6.0,
                                  thicknessWhileDragging: 10.0,
                                  child: ListView(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16.0),
                                    children: [
                                      if (_errorMessage.isNotEmpty && _hasData())
                                        ...[
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
