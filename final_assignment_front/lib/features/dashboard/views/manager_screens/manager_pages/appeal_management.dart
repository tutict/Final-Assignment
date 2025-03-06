import 'dart:developer' as developer;
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 申诉管理页面（管理员端，仅审批功能）
class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  late AppealManagementControllerApi appealApi;
  late Future<List<AppealManagement>> _appealsFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _scrollController = ScrollController();
    _loadAppeals(); // 加载所有申诉记录
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载所有申诉信息
  Future<void> _loadAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未登录，请重新登录');
      // Assuming ApiClient has a setJwtToken method; otherwise, headers handle it
      if (appealApi.apiClient.setJwtToken != null) {
        appealApi.apiClient.setJwtToken(jwtToken);
      }
      _appealsFuture =
          appealApi.apiAppealsGet(); // Assign future after JWT is set
      await _appealsFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching appeals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉信息失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  /// 按姓名搜索申诉信息
  Future<void> _searchAppealsByName(String query) async {
    if (query.isEmpty) {
      _loadAppeals();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未登录，请重新登录');
      if (appealApi.apiClient.setJwtToken != null) {
        appealApi.apiClient.setJwtToken(jwtToken);
      }
      _appealsFuture = appealApi.apiAppealsNameAppealNameGet(appealName: query);
      await _appealsFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error searching appeals by name: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, '/login'); // Adjust route name as needed
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToDetailPage(AppealManagement appeal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppealDetailPage(appeal: appeal)),
    ).then((value) {
      if (value == true && mounted) {
        _loadAppeals(); // 刷新列表
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: isLight
          ? themeData.colorScheme.surface.withOpacity(0.95)
          : themeData.colorScheme.surface.withOpacity(0.85),
      appBar: AppBar(
        title: Text(
          '申诉审批管理',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer.withOpacity(0.9)
            : themeData.colorScheme.surfaceContainer.withOpacity(0.7),
        elevation: 2,
        shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '按姓名搜索申诉',
                      prefixIcon: Icon(Icons.search,
                          color: themeData.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            BorderSide(color: themeData.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurface
                            : themeData.colorScheme.onSurface.withOpacity(0.9),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurface.withOpacity(0.95),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () =>
                      _searchAppealsByName(_searchController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.colorScheme.primary,
                    foregroundColor: themeData.colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  child: Text(
                    '搜索',
                    style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            themeData.colorScheme.primary),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: themeData.textTheme.bodyLarge?.copyWith(
                              color: isLight
                                  ? themeData.colorScheme.onSurface
                                  : themeData.colorScheme.onSurface
                                      .withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        )
                      : CupertinoScrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          thickness: 6.0,
                          thicknessWhileDragging: 10.0,
                          child: FutureBuilder<List<AppealManagement>>(
                            future: _appealsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        themeData.colorScheme.primary),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    '加载申诉信息失败: ${snapshot.error}',
                                    style:
                                        themeData.textTheme.bodyLarge?.copyWith(
                                      color: isLight
                                          ? themeData.colorScheme.onSurface
                                          : themeData.colorScheme.onSurface
                                              .withOpacity(0.9),
                                      fontSize: 18,
                                    ),
                                  ),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text(
                                    '暂无申诉记录',
                                    style:
                                        themeData.textTheme.bodyLarge?.copyWith(
                                      color: isLight
                                          ? themeData.colorScheme.onSurface
                                          : themeData.colorScheme.onSurface
                                              .withOpacity(0.9),
                                      fontSize: 18,
                                    ),
                                  ),
                                );
                              } else {
                                final appeals = snapshot.data!;
                                return RefreshIndicator(
                                  onRefresh: _loadAppeals,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: appeals.length,
                                    itemBuilder: (context, index) {
                                      final appeal = appeals[index];
                                      return Card(
                                        elevation: 3,
                                        shadowColor: themeData
                                            .colorScheme.shadow
                                            .withOpacity(0.2),
                                        color: isLight
                                            ? themeData
                                                .colorScheme.surfaceContainerLow
                                            : themeData.colorScheme
                                                .surfaceContainerHigh,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0)),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6.0),
                                        child: ListTile(
                                          title: Text(
                                            '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                                            style: themeData.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: isLight
                                                  ? themeData
                                                      .colorScheme.onSurface
                                                  : themeData
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.95),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: isLight
                                                  ? themeData.colorScheme
                                                      .onSurfaceVariant
                                                  : themeData.colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.85),
                                            ),
                                          ),
                                          onTap: () => _goToDetailPage(appeal),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 申诉详情页面（管理员端，带审批功能）
class AppealDetailPage extends StatefulWidget {
  final AppealManagement appeal;

  const AppealDetailPage({super.key, required this.appeal});

  @override
  State<AppealDetailPage> createState() => _AppealDetailPageState();
}

class _AppealDetailPageState extends State<AppealDetailPage> {
  final appealApi = AppealManagementControllerApi();
  bool _isLoading = false;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  Future<void> _approveAppeal(String appealId) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未登录，请重新登录');
      if (appealApi.apiClient.setJwtToken != null) {
        appealApi.apiClient.setJwtToken(jwtToken);
      }
      final updatedAppeal = AppealManagement(
        appealId: widget.appeal.appealId,
        offenseId: widget.appeal.offenseId,
        appellantName: widget.appeal.appellantName,
        idCardNumber: widget.appeal.idCardNumber,
        contactNumber: widget.appeal.contactNumber,
        appealReason: widget.appeal.appealReason,
        appealTime: widget.appeal.appealTime,
        processStatus: 'Approved',
        processResult: '申诉已通过',
        idempotencyKey: widget.appeal.idempotencyKey,
      );
      await appealApi.apiAppealsAppealIdPut(
        appealId: appealId,
        appealManagement: updatedAppeal,
        idempotencyKey:
            widget.appeal.idempotencyKey ?? generateIdempotencyKey(),
      );
      _showSnackBar('申诉已审批通过！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('审批失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAppeal(String appealId) async {
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer
            : themeData.colorScheme.surfaceContainerHigh,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300.0, minHeight: 200.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '驳回申诉',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: '驳回原因',
                    labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurfaceVariant
                          : themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.85),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? themeData.colorScheme.surfaceContainerLowest
                        : themeData.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 2.0),
                    ),
                  ),
                  maxLines: 3,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: themeData.colorScheme.onSurface,
                      ),
                      child: Text(
                        '取消',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: themeData.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reason = _rejectionReasonController.text.trim();
                        if (reason.isEmpty) {
                          _showSnackBar('请填写驳回原因');
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final jwtToken = prefs.getString('jwtToken');
                          if (jwtToken == null) throw Exception('未登录，请重新登录');
                          if (appealApi.apiClient.setJwtToken != null) {
                            appealApi.apiClient.setJwtToken(jwtToken);
                          }
                          final updatedAppeal = AppealManagement(
                            appealId: widget.appeal.appealId,
                            offenseId: widget.appeal.offenseId,
                            appellantName: widget.appeal.appellantName,
                            idCardNumber: widget.appeal.idCardNumber,
                            contactNumber: widget.appeal.contactNumber,
                            appealReason: widget.appeal.appealReason,
                            appealTime: widget.appeal.appealTime,
                            processStatus: 'Rejected',
                            processResult: reason,
                            idempotencyKey: widget.appeal.idempotencyKey,
                          );
                          await appealApi.apiAppealsAppealIdPut(
                            appealId: appealId,
                            appealManagement: updatedAppeal,
                            idempotencyKey: widget.appeal.idempotencyKey ??
                                generateIdempotencyKey(),
                          );
                          _showSnackBar('申诉已驳回，用户可重新提交');
                          Navigator.pop(ctx);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          _showSnackBar('驳回失败: $e');
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.error,
                        foregroundColor: themeData.colorScheme.onError,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                      ),
                      child: Text(
                        '确认驳回',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: themeData.colorScheme.onError,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;
    final appealId = widget.appeal.appealId?.toString() ?? '未提供';
    final offenseId = widget.appeal.offenseId?.toString() ?? '未提供';
    final name = widget.appeal.appellantName ?? '未提供';
    final idCard = widget.appeal.idCardNumber ?? '未提供';
    final contact = widget.appeal.contactNumber ?? '未提供';
    final reason = widget.appeal.appealReason ?? '未提供';
    final time = widget.appeal.appealTime?.toIso8601String() ?? '未提供';
    final status = widget.appeal.processStatus ?? '未提供';
    final result = widget.appeal.processResult ?? '未提供';

    return Scaffold(
      backgroundColor: isLight
          ? themeData.colorScheme.surface.withOpacity(0.95)
          : themeData.colorScheme.surface.withOpacity(0.85),
      appBar: AppBar(
        title: Text(
          '申诉详情',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer.withOpacity(0.9)
            : themeData.colorScheme.surfaceContainer.withOpacity(0.7),
        elevation: 2,
        shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      themeData.colorScheme.primary),
                ),
              )
            : CupertinoScrollbar(
                thumbVisibility: true,
                thickness: 6.0,
                thicknessWhileDragging: 10.0,
                child: ListView(
                  children: [
                    _buildDetailRow('申诉ID', appealId, themeData, isLight),
                    _buildDetailRow('违法记录ID', offenseId, themeData, isLight),
                    _buildDetailRow('上诉人姓名', name, themeData, isLight),
                    _buildDetailRow('身份证号码', idCard, themeData, isLight),
                    _buildDetailRow('联系电话', contact, themeData, isLight),
                    _buildDetailRow('上诉原因', reason, themeData, isLight),
                    _buildDetailRow('上诉时间', time, themeData, isLight),
                    _buildDetailRow('处理状态', status, themeData, isLight),
                    _buildDetailRow('处理结果', result, themeData, isLight),
                    const SizedBox(height: 20),
                    if (status == 'Pending') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _approveAppeal(appealId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 12.0),
                            ),
                            child: Text(
                              '通过',
                              style: themeData.textTheme.labelLarge?.copyWith(
                                color: themeData.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _rejectAppeal(appealId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.error,
                              foregroundColor: themeData.colorScheme.onError,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 12.0),
                            ),
                            child: Text(
                              '驳回',
                              style: themeData.textTheme.labelLarge?.copyWith(
                                color: themeData.colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '此申诉已处理，无法再次审批',
                          style: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeData themeData, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.95),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: isLight
                    ? themeData.colorScheme.onSurfaceVariant
                    : themeData.colorScheme.onSurfaceVariant.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
