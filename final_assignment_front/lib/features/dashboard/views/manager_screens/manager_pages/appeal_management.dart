import 'dart:developer' as developer;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  late ScrollController _scrollController;

  final DashboardController controller = Get.find<DashboardController>();

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
      final appeals = await appealApi.apiAppealsGet() ?? [];
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

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      debugPrint('Fetching appeal reason suggestions for prefix: $prefix');
      return await appealApi.apiAppealsAutocompleteReasonGet(
        prefix: prefix,
        maxSuggestions: 5,
      );
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _applyFilters({bool reset = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await appealApi.initializeWithJwt();
      final searchQuery = _searchController.text.trim();

      if (reset) {
        _startTime = null;
        _endTime = null;
        _searchController.clear();
      }

      List<AppealManagement> appeals = [];
      if (searchQuery.isEmpty && _startTime == null && _endTime == null) {
        debugPrint('Fetching all appeals');
        appeals = await appealApi.apiAppealsGet() ?? [];
      } else if (searchQuery.isNotEmpty &&
          _startTime != null &&
          _endTime != null) {
        debugPrint('Filtering by reason and time range');
        appeals =
            await appealApi.apiAppealsReasonReasonGet(reason: searchQuery) ??
                [];
        appeals = appeals
            .where((appeal) =>
                appeal.appealTime != null &&
                appeal.appealTime!.isAfter(_startTime!) &&
                appeal.appealTime!.isBefore(_endTime!))
            .toList();
      } else if (searchQuery.isNotEmpty) {
        debugPrint('Searching appeals by reason: $searchQuery');
        appeals =
            await appealApi.apiAppealsReasonReasonGet(reason: searchQuery) ??
                [];
      } else if (_startTime != null && _endTime != null) {
        debugPrint('Filtering by time range');
        appeals = await appealApi.apiAppealsTimeRangeGet(
              startTime: _startTime!.toIso8601String(),
              endTime: _endTime!.toIso8601String(),
            ) ??
            [];
      }

      setState(() {
        _appeals = appeals;
        if (_appeals.isEmpty) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
                  ? '未找到符合条件的申诉记录'
                  : '暂无申诉记录';
        }
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
    Get.offAllNamed(AppPages.login);
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
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
      ),
    );
  }

  void _goToDetailPage(AppealManagement appeal) {
    Get.to(() => AppealDetailPage(appeal: appeal))?.then((value) {
      if (value == true && mounted) _applyFilters();
    });
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 2,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
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
                      _applyFilters();
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      _searchController.text =
                          controller.text; // Sync with outer controller
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: '搜索申诉原因',
                          hintStyle: TextStyle(
                              color: themeData.colorScheme.onSurface
                                  .withOpacity(0.6)),
                          prefixIcon: Icon(Icons.search,
                              color: themeData.colorScheme.primary),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    controller.clear();
                                    _searchController.clear();
                                    _applyFilters(reset: true);
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: themeData.colorScheme.outline
                                    .withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: themeData.colorScheme.primary,
                                width: 1.5),
                          ),
                          filled: true,
                          fillColor:
                              themeData.colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                        ),
                        onSubmitted: (value) => _applyFilters(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startTime != null && _endTime != null
                        ? '日期范围: ${_startTime!.toString().split(' ')[0]} 至 ${_endTime!.toString().split(' ')[0]}'
                        : '选择日期范围',
                    style: TextStyle(
                      color: _startTime != null && _endTime != null
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range,
                      color: themeData.colorScheme.primary),
                  tooltip: '按日期范围搜索',
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('zh', 'CN'),
                      helpText: '选择日期范围',
                      cancelText: '取消',
                      confirmText: '确定',
                      fieldStartHintText: '开始日期',
                      fieldEndHintText: '结束日期',
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: themeData,
                          child: child!,
                        );
                      },
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
                    tooltip: '清除日期范围',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(AppealManagement appeal, ThemeData themeData) {
    return Card(
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _goToDetailPage(appeal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '申诉审批管理',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(themeData),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CupertinoActivityIndicator(
                              color: themeData.colorScheme.primary,
                              radius: 16.0,
                            ),
                          )
                        : _errorMessage.isNotEmpty
                            ? Center(
                                child: Text(
                                  _errorMessage,
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.error,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : _appeals.isEmpty
                                ? Center(
                                    child: Text(
                                      '暂无申诉记录',
                                      style: themeData.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : CupertinoScrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    thickness: 6.0,
                                    thicknessWhileDragging: 10.0,
                                    child: RefreshIndicator(
                                      onRefresh: _applyFilters,
                                      color: themeData.colorScheme.primary,
                                      backgroundColor: themeData
                                          .colorScheme.surfaceContainer,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: _appeals.length,
                                        itemBuilder: (context, index) {
                                          final appeal = _appeals[index];
                                          return _buildAppealCard(
                                              appeal, themeData);
                                        },
                                      ),
                                    ),
                                  ),
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

class AppealDetailPage extends StatefulWidget {
  final AppealManagement appeal;

  const AppealDetailPage({super.key, required this.appeal});

  @override
  State<AppealDetailPage> createState() => _AppealDetailPageState();
}

class _AppealDetailPageState extends State<AppealDetailPage> {
  final appealApi = AppealManagementControllerApi();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();
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
      builder: (ctx) => Theme(
        data: themeData,
        child: Dialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 300.0, minHeight: 200.0),
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
                      fillColor: themeData.colorScheme.surfaceContainerLow,
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
                        style: themeData.elevatedButtonTheme.style?.copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                              themeData.colorScheme.error),
                          foregroundColor: WidgetStatePropertyAll(
                              themeData.colorScheme.onError),
                        ),
                        child: Text(
                          '确认驳回',
                          style: themeData.textTheme.labelMedium?.copyWith(
                            color: themeData.colorScheme.onError,
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
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
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
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '申诉详情',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : CupertinoScrollbar(
                      controller: ScrollController(),
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
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
                                    _buildDetailRow(
                                        '申诉ID', appealId, themeData),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _approveAppeal(appealId),
                                    icon: const Icon(CupertinoIcons.checkmark),
                                    label: const Text('通过'),
                                    style: themeData.elevatedButtonTheme.style,
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _rejectAppeal(appealId),
                                    icon: const Icon(CupertinoIcons.xmark),
                                    label: const Text('驳回'),
                                    style: themeData.elevatedButtonTheme.style
                                        ?.copyWith(
                                      backgroundColor: WidgetStatePropertyAll(
                                          themeData.colorScheme.error),
                                      foregroundColor: WidgetStatePropertyAll(
                                          themeData.colorScheme.onError),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Center(
                                child: Text(
                                  '此申诉已处理，无法再次审批',
                                  style:
                                      themeData.textTheme.bodyMedium?.copyWith(
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
