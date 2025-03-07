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
    _loadAppeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未登录，请重新登录');
      await appealApi.initializeWithJwt(); // Assuming this sets the JWT
      _appealsFuture = appealApi.apiAppealsGet();
      await _appealsFuture;
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error fetching appeals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉信息失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

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
      await appealApi.initializeWithJwt();
      _appealsFuture = appealApi.apiAppealsNameAppealNameGet(appealName: query);
      await _appealsFuture;
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching appeals by name: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  void _goToDetailPage(AppealManagement appeal) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AppealDetailPage(appeal: appeal)))
        .then((value) {
      if (value == true && mounted) _loadAppeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('申诉审批管理',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
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
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                        onSubmitted: (value) =>
                            _searchAppealsByName(value.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _searchAppealsByName(_searchController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Text(_errorMessage,
                                  style: theme.textTheme.bodyLarge))
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
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            '加载申诉信息失败: ${snapshot.error}',
                                            style: theme.textTheme.bodyLarge));
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text('暂无申诉记录',
                                            style: theme.textTheme.bodyLarge));
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
                                            elevation: 4,
                                            color: theme.colorScheme.surface,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.0)),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: ListTile(
                                              title: Text(
                                                '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                              subtitle: Text(
                                                '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7)),
                                              ),
                                              onTap: () =>
                                                  _goToDetailPage(appeal),
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
      await appealApi.initializeWithJwt();
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.surface,
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
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: '驳回原因',
                    labelStyle: theme.textTheme.bodyMedium,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary)),
                  ),
                  maxLines: 3,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('取消', style: theme.textTheme.bodyMedium),
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
                          await appealApi.initializeWithJwt();
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
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor:
                            MaterialStateProperty.all(theme.colorScheme.error),
                        foregroundColor: MaterialStateProperty.all(
                            theme.colorScheme.onError),
                      ),
                      child: const Text('确认驳回'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appealId = widget.appeal.appealId?.toString() ?? '未提供';
    final offenseId = widget.appeal.offenseId?.toString() ?? '未提供';
    final name = widget.appeal.appellantName ?? '未提供';
    final idCard = widget.appeal.idCardNumber ?? '未提供';
    final contact = widget.appeal.contactNumber ?? '未提供';
    final reason = widget.appeal.appealReason ?? '未提供';
    final time = widget.appeal.appealTime?.toIso8601String() ?? '未提供';
    final status = widget.appeal.processStatus ?? '未提供';
    final result = widget.appeal.processResult ?? '未提供';

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('申诉详情',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CupertinoScrollbar(
                    thumbVisibility: true,
                    thickness: 6.0,
                    thicknessWhileDragging: 10.0,
                    child: ListView(
                      children: [
                        _buildDetailRow('申诉ID', appealId, theme),
                        _buildDetailRow('违法记录ID', offenseId, theme),
                        _buildDetailRow('上诉人姓名', name, theme),
                        _buildDetailRow('身份证号码', idCard, theme),
                        _buildDetailRow('联系电话', contact, theme),
                        _buildDetailRow('上诉原因', reason, theme),
                        _buildDetailRow('上诉时间', time, theme),
                        _buildDetailRow('处理状态', status, theme),
                        _buildDetailRow('处理结果', result, theme),
                        const SizedBox(height: 20),
                        if (status == 'Pending') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _approveAppeal(appealId),
                                style: theme.elevatedButtonTheme.style,
                                child: const Text('通过'),
                              ),
                              ElevatedButton(
                                onPressed: () => _rejectAppeal(appealId),
                                style:
                                    theme.elevatedButtonTheme.style?.copyWith(
                                  backgroundColor: MaterialStateProperty.all(
                                      theme.colorScheme.error),
                                  foregroundColor: MaterialStateProperty.all(
                                      theme.colorScheme.onError),
                                ),
                                child: const Text('驳回'),
                              ),
                            ],
                          ),
                        ] else
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '此申诉已处理，无法再次审批',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}
