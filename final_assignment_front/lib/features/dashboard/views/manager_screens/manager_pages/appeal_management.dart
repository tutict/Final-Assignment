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

class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  late AppealManagementControllerApi appealApi;
  List<AppealManagement> _appeals = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  late ScrollController _scrollController;

  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  // Filter options
  String? _selectedStatus;
  DateTime? _startTime;
  DateTime? _endTime;

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
    _reasonController.dispose();
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
      await appealApi.initializeWithJwt();
      final appeals = await appealApi.apiAppealsGet();
      setState(() {
        _appeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching appeals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉信息失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await appealApi.initializeWithJwt();
      if (_selectedStatus != null && _startTime != null && _endTime != null) {
        _appeals = await appealApi.apiAppealsStatusAndTimeGet(
          processStatus: _selectedStatus!,
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.toIso8601String(),
        );
      } else if (_selectedStatus != null) {
        _appeals = await appealApi.apiAppealsStatusProcessStatusGet(
            processStatus: _selectedStatus!);
      } else if (_startTime != null && _endTime != null) {
        _appeals = await appealApi.apiAppealsTimeRangeGet(
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.toIso8601String(),
        );
      } else if (_reasonController.text.isNotEmpty) {
        _appeals = await appealApi.apiAppealsReasonReasonGet(
            reason: _reasonController.text.trim());
      } else if (_searchController.text.isNotEmpty) {
        _appeals = await appealApi.apiAppealsNameAppellantNameGet(
            appellantName: _searchController.text.trim());
      } else {
        _appeals = await appealApi.apiAppealsGet();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error applying filters: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '过滤失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onErrorContainer
                  : themeData.colorScheme.onPrimaryContainer),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _goToDetailPage(AppealManagement appeal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppealDetailPage(appeal: appeal)),
    ).then((value) {
      if (value == true && mounted) _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              '申诉审批管理',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: '按姓名搜索',
                                  prefixIcon: Icon(Icons.search,
                                      color: themeData.colorScheme.primary),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  filled: true,
                                  fillColor: themeData
                                      .colorScheme.surfaceContainerLowest,
                                ),
                                onSubmitted: (value) => _applyFilters(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              hint: const Text('状态'),
                              value: _selectedStatus,
                              items: ['Pending', 'Approved', 'Rejected']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _reasonController,
                                decoration: InputDecoration(
                                  labelText: '按原因搜索',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  filled: true,
                                  fillColor: themeData
                                      .colorScheme.surfaceContainerLowest,
                                ),
                                onSubmitted: (value) => _applyFilters(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.date_range),
                              onPressed: () async {
                                final range = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
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
                          ],
                        ),
                      ],
                    ),
                  ),
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
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                            )
                          : _appeals.isEmpty
                              ? Center(
                                  child: Text(
                                    '暂无申诉记录',
                                    style:
                                        themeData.textTheme.bodyLarge?.copyWith(
                                      color: themeData.colorScheme.onSurface,
                                    ),
                                  ),
                                )
                              : CupertinoScrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  child: RefreshIndicator(
                                    onRefresh: _applyFilters,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: _appeals.length,
                                      itemBuilder: (context, index) {
                                        final appeal = _appeals[index];
                                        return Card(
                                          elevation: 3,
                                          color: themeData
                                              .colorScheme.surfaceContainer,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0)),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6.0),
                                          child: ListTile(
                                            title: Text(
                                              '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                                              style: themeData
                                                  .textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: themeData
                                                    .colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: themeData.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            trailing: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  themeData.colorScheme.primary,
                                              size: 16,
                                            ),
                                            onTap: () =>
                                                _goToDetailPage(appeal),
                                          ),
                                        );
                                      },
                                    ),
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
      );
      await appealApi.apiAppealsAppealIdPut(
        appealId: appealId,
        appealManagement: updatedAppeal,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('申诉已审批通过！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('审批失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAppeal(String appealId) async {
    final themeData = controller.currentBodyTheme.value;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
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
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: '驳回原因',
                    labelStyle: TextStyle(
                        color: themeData.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        '取消',
                        style: themeData.textTheme.labelMedium?.copyWith(
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reason = _rejectionReasonController.text.trim();
                        if (reason.isEmpty) {
                          _showSnackBar('请填写驳回原因', isError: true);
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
                          );
                          await appealApi.apiAppealsAppealIdPut(
                            appealId: appealId,
                            appealManagement: updatedAppeal,
                            idempotencyKey: generateIdempotencyKey(),
                          );
                          _showSnackBar('申诉已驳回，用户可重新提交');
                          Navigator.pop(ctx);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          _showSnackBar('驳回失败: $e', isError: true);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.error,
                        foregroundColor: themeData.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onErrorContainer
                  : themeData.colorScheme.onPrimaryContainer),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              '申诉详情',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            color: themeData.colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('申诉ID', appealId, themeData),
                                  _buildDetailRow(
                                      '违法记录ID', offenseId, themeData),
                                  _buildDetailRow('上诉人姓名', name, themeData),
                                  _buildDetailRow('身份证号码', idCard, themeData),
                                  _buildDetailRow('联系电话', contact, themeData),
                                  _buildDetailRow('上诉原因', reason, themeData),
                                  _buildDetailRow('上诉时间', time, themeData),
                                  _buildDetailRow('处理状态', status, themeData),
                                  _buildDetailRow('处理结果', result, themeData),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (status == 'Pending') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _approveAppeal(appealId),
                                  icon: const Icon(Icons.check),
                                  label: const Text('通过'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.primary,
                                    foregroundColor:
                                        themeData.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _rejectAppeal(appealId),
                                  icon: const Icon(Icons.close),
                                  label: const Text('驳回'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.error,
                                    foregroundColor:
                                        themeData.colorScheme.onError,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Center(
                              child: Text(
                                '此申诉已处理，无法再次审批',
                                style: themeData.textTheme.bodyMedium?.copyWith(
                                  color: themeData.colorScheme.error,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
    });
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
}
