import 'package:final_assignment_front/features/api/backup_restore_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/shared/controllers/base_list_controller.dart';
import 'package:final_assignment_front/shared/utils/error_handler.dart';
import 'package:final_assignment_front/utils/widgets/index.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

String generateIdempotencyKey() => const Uuid().v4();

class BackupAndRestoreListController extends BaseListController<BackupRestore> {
  @override
  Future<void> fetchData() async {}
}

/// 备份与恢复管理页面
class BackupAndRestorePage extends StatefulWidget {
  const BackupAndRestorePage({super.key});

  @override
  State<BackupAndRestorePage> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestorePage> {
  final BackupRestoreControllerApi backupApi = BackupRestoreControllerApi();
  final ManagerDashboardController controller =
      Get.find<ManagerDashboardController>();
  final BackupAndRestoreListController listController = Get.put(
    BackupAndRestoreListController(),
    tag: 'backupAndRestorePage',
  );
  final List<BackupRestore> _backups = [];
  List<BackupRestore> _filteredBackups = [];
  bool _apiInitialized = false;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _backupTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    listController.isLoading.value = true;
    _initialize(); // 检查用户角色并加载备份
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _backupTimeController.dispose();
    Get.delete<BackupAndRestoreListController>(tag: 'backupAndRestorePage');
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      listController.isLoading.value = true;
      _errorMessage = '';
    });
    try {
      if (!await _ensureApiInitialized()) {
        setState(() {
          _errorMessage = '未登录，请重新登录';
          listController.isLoading.value = false;
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('未登录，请重新登录');
      }
      final roles = _extractRoles(jwtToken);
      final isAdmin = roles.any((role) => role.toUpperCase().contains('ADMIN'));
      if (!isAdmin) {
        setState(() {
          _isAdmin = false;
          _errorMessage = '权限不足：仅管理员可访问此页面';
          listController.isLoading.value = false;
        });
        return;
      }
      setState(() => _isAdmin = true);
      await _loadBackups();
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: ${_formatErrorMessage(e)}';
        listController.isLoading.value = false;
      });
    }
  }

  Future<bool> _ensureApiInitialized() async {
    if (_apiInitialized) return true;
    try {
      await backupApi.initializeWithJwt();
      _apiInitialized = true;
      return true;
    } catch (e) {
      ErrorHandler.showError(e, fallbackMessage: '初始化备份服务失败，请重新登录');
      return false;
    }
  }

  List<String> _extractRoles(String jwtToken) {
    final decoded = JwtDecoder.decode(jwtToken);
    final rolesField = decoded['roles'];
    if (rolesField is List) {
      return rolesField.map((role) => role.toString()).toList();
    }
    if (rolesField is String) {
      return [rolesField];
    }
    return [];
  }

  Future<void> _loadBackups() async {
    if (!_isAdmin) {
      setState(() => listController.isLoading.value = false);
      return;
    }
    if (!await _ensureApiInitialized()) {
      setState(() {
        listController.isLoading.value = false;
        _errorMessage = '未登录，请重新登录';
      });
      return;
    }
    setState(() {
      listController.isLoading.value = true;
      _errorMessage = '';
    });

    try {
      final backups = await backupApi.listBackups();
      setState(() {
        _backups
          ..clear()
          ..addAll(backups);
        _filteredBackups = List<BackupRestore>.from(_backups);
        listController.isLoading.value = false;
      });
    } catch (e) {
      setState(() {
        listController.isLoading.value = false;
        _errorMessage = '加载备份记录失败: ${_formatErrorMessage(e)}';
        _filteredBackups = [];
      });
    }
  }

  void _searchBackups(String type, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _filteredBackups = List.from(_backups));
      return;
    }
    final lowerQuery = trimmed.toLowerCase();
    List<BackupRestore> filtered;
    if (type == 'filename') {
      filtered = _backups
          .where((backup) =>
              (backup.backupFileName ?? '').toLowerCase().contains(lowerQuery))
          .toList();
    } else if (type == 'time') {
      filtered = _backups
          .where((backup) => _formatDate(backup.backupTime).contains(trimmed))
          .toList();
    } else {
      filtered = List.from(_backups);
    }
    setState(() => _filteredBackups = filtered);
  }

  Future<void> _createBackup() async {
    if (!mounted || !_isAdmin) return;

    if (!await _ensureApiInitialized()) {
      ErrorHandler.showError(Exception('未登录，请重新登录'),
          fallbackMessage: '未登录，请重新登录');
      return;
    }

    try {
      final backupName =
          'backup_${DateTime.now().millisecondsSinceEpoch.toString()}';
      final idempotencyKey = generateIdempotencyKey();

      final newBackup = BackupRestore(
        backupFileName: backupName,
        backupTime: DateTime.now(),
        remarks: '手动创建的备份',
        status: 'PENDING',
        idempotencyKey: idempotencyKey,
      );

      await backupApi.createBackup(
        backupRestore: newBackup,
        idempotencyKey: idempotencyKey,
      );

      Get.snackbar('成功', '备份创建成功', snackPosition: SnackPosition.BOTTOM);
      await _loadBackups();
    } catch (e) {
      ErrorHandler.showError(e,
          fallbackMessage: '创建备份失败: ${_formatErrorMessage(e)}');
    }
  }

  Future<void> _updateBackup(int backupId, BackupRestore updatedBackup) async {
    if (!mounted || !_isAdmin) return;

    if (!await _ensureApiInitialized()) {
      ErrorHandler.showError(Exception('未登录，请重新登录'),
          fallbackMessage: '未登录，请重新登录');
      return;
    }

    try {
      final idempotencyKey = generateIdempotencyKey();
      final payload = updatedBackup.copyWith(idempotencyKey: idempotencyKey);
      await backupApi.updateBackup(
        backupId: backupId,
        backupRestore: payload,
        idempotencyKey: idempotencyKey,
      );
      Get.snackbar('成功', '备份更新成功', snackPosition: SnackPosition.BOTTOM);
      await _loadBackups();
    } catch (e) {
      ErrorHandler.showError(e,
          fallbackMessage: '更新备份失败: ${_formatErrorMessage(e)}');
    }
  }

  Future<void> _restoreBackup(BackupRestore backup) async {
    if (!mounted || !_isAdmin || backup.backupId == null) return;

    if (!await _ensureApiInitialized()) {
      ErrorHandler.showError(Exception('未登录，请重新登录'),
          fallbackMessage: '未登录，请重新登录');
      return;
    }

    try {
      final idempotencyKey = generateIdempotencyKey();
      final payload = backup.copyWith(
        restoreTime: DateTime.now(),
        restoreStatus: 'RESTORED',
        status: 'RESTORED',
        idempotencyKey: idempotencyKey,
      );
      await backupApi.updateBackup(
        backupId: backup.backupId!,
        backupRestore: payload,
        idempotencyKey: idempotencyKey,
      );
      Get.snackbar('成功', '恢复备份成功', snackPosition: SnackPosition.BOTTOM);
      await _loadBackups();
    } catch (e) {
      ErrorHandler.showError(e,
          fallbackMessage: '恢复备份失败: ${_formatErrorMessage(e)}');
    }
  }

  Future<void> _deleteBackup(int backupId) async {
    if (!mounted || !_isAdmin) return;

    if (!await _ensureApiInitialized()) {
      ErrorHandler.showError(Exception('未登录，请重新登录'),
          fallbackMessage: '未登录，请重新登录');
      return;
    }

    try {
      await backupApi.deleteBackup(backupId: backupId);
      Get.snackbar('成功', '删除备份成功', snackPosition: SnackPosition.BOTTOM);
      await _loadBackups();
    } catch (e) {
      ErrorHandler.showError(e,
          fallbackMessage: '删除备份失败: ${_formatErrorMessage(e)}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppException) {
      final message = error.message.isNotEmpty ? error.message : '服务器错误';
      return '$message (HTTP ${error.code})';
    }
    return error.toString();
  }

  void _goToDetailPage(BackupRestore backup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupDetailPage(backup: backup),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadBackups();
      }
    });
  }

  void _showUpdateBackupDialog(BackupRestore backup) {
    final TextEditingController fileNameController =
        TextEditingController(text: backup.backupFileName ?? '');
    final TextEditingController remarksController =
        TextEditingController(text: backup.remarks ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑备份'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: const InputDecoration(labelText: '文件名'),
              ),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final String fileName = fileNameController.text.trim();
              final String remarks = remarksController.text.trim();

              if (fileName.isEmpty) {
                _showSnackBar('文件名不能为空');
                return;
              }

              final updatedBackup = backup.copyWith(
                backupFileName: fileName,
                remarks: remarks,
              );

              _updateBackup(backup.backupId!, updatedBackup);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // Helper method to format DateTime to a readable string
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return "${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Obx(() => DashboardPageTemplate(
            theme: controller.currentBodyTheme.value,
            title: '备份与恢复管理',
            pageType: DashboardPageType.manager,
            isLoading: listController.isLoading.value,
            errorMessage:
                _errorMessage.isNotEmpty ? _errorMessage : '权限不足：仅管理员可访问此页面',
            body: const SizedBox.shrink(),
          ));
    }

    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final bool isLight = themeData.brightness == Brightness.light;
      return DashboardPageTemplate(
        theme: themeData,
        title: '备份与恢复管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.add,
            onPressed: _createBackup,
            tooltip: '创建新备份',
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fileNameController,
                      decoration: InputDecoration(
                        labelText: '按文件名搜索备份',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        labelStyle: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.grey : Colors.grey[500]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.blue : Colors.blueGrey,
                          ),
                        ),
                      ),
                      onChanged: (value) =>
                          _searchBackups('filename', value.trim()),
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _searchBackups(
                        'filename', _fileNameController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('搜索'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _backupTimeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '按备份时间搜索',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        labelStyle: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.grey : Colors.grey[500]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.blue : Colors.blueGrey,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) => Theme(
                            data: ThemeData(
                              primaryColor:
                                  isLight ? Colors.blue : Colors.blueGrey,
                              colorScheme: ColorScheme.light(
                                primary:
                                    isLight ? Colors.blue : Colors.blueGrey,
                              ).copyWith(
                                  secondary:
                                      isLight ? Colors.blue : Colors.blueGrey),
                            ),
                            child: child!,
                          ),
                        );
                        if (pickedDate != null) {
                          final formatted =
                              "${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          _backupTimeController.text = formatted;
                          _searchBackups('time', formatted);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _searchBackups(
                        'time', _backupTimeController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('搜索'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: listController.isLoading.value
                    ? const LoadingView()
                    : _errorMessage.isNotEmpty
                        ? ErrorStateView(message: _errorMessage)
                        : _filteredBackups.isEmpty
                            ? const EmptyStateView(
                                message: '没有找到备份记录',
                                icon: Icons.backup_outlined,
                              )
                            : RefreshIndicator(
                                onRefresh: _loadBackups,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filteredBackups.length,
                                  itemBuilder: (context, index) {
                                    final backup = _filteredBackups[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      elevation: 4,
                                      color: isLight
                                          ? Colors.white
                                          : Colors.grey[800],
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          '文件名: ${backup.backupFileName ?? '无'}',
                                          style: TextStyle(
                                            color: isLight
                                                ? Colors.black87
                                                : Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '备份时间: ${_formatDateTime(backup.backupTime)}\n恢复时间: ${_formatDateTime(backup.restoreTime)}\n恢复状态: ${backup.restoreStatus ?? '未恢复'}',
                                          style: TextStyle(
                                            color: isLight
                                                ? Colors.black54
                                                : Colors.white70,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.restore,
                                                color: isLight
                                                    ? Colors.green
                                                    : Colors.green[300],
                                              ),
                                              onPressed: () =>
                                                  _restoreBackup(backup),
                                              tooltip: '恢复此备份',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: isLight
                                                    ? Colors.blue
                                                    : Colors.blue[300],
                                              ),
                                              onPressed: () =>
                                                  _showUpdateBackupDialog(
                                                      backup),
                                              tooltip: '编辑此备份',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: isLight
                                                    ? Colors.red
                                                    : Colors.red[300],
                                              ),
                                              onPressed: () => _deleteBackup(
                                                  backup.backupId!),
                                              tooltip: '删除此备份',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.info,
                                                color: isLight
                                                    ? Colors.blue
                                                    : Colors.blue[300],
                                              ),
                                              onPressed: () =>
                                                  _goToDetailPage(backup),
                                              tooltip: '查看详情',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class BackupDetailPage extends StatefulWidget {
  final BackupRestore backup;

  const BackupDetailPage({super.key, required this.backup});

  @override
  State<BackupDetailPage> createState() => _BackupDetailPageState();
}

class _BackupDetailPageState extends State<BackupDetailPage> {
  final BackupRestoreControllerApi _backupApi = BackupRestoreControllerApi();
  final TextEditingController _remarksController = TextEditingController();
  bool _apiInitialized = false;
  final RxBool isLoading = false.obs;
  bool _isAdmin = false;
  late BackupRestore _backup;

  @override
  void initState() {
    super.initState();
    _backup = widget.backup;
    _remarksController.text = _backup.remarks ?? '';
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => isLoading.value = true);
    try {
      if (!await _ensureApiInitialized()) {
        setState(() => isLoading.value = false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');
      if (token == null || token.isEmpty) {
        setState(() {
          _isAdmin = false;
          isLoading.value = false;
        });
        return;
      }
      final roles = _extractRoles(token);
      setState(() {
        _isAdmin = roles.any((role) => role.toUpperCase().contains('ADMIN'));
        isLoading.value = false;
      });
    } catch (_) {
      setState(() {
        _isAdmin = false;
        isLoading.value = false;
      });
    }
  }

  Future<bool> _ensureApiInitialized() async {
    if (_apiInitialized) return true;
    try {
      await _backupApi.initializeWithJwt();
      _apiInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  List<String> _extractRoles(String token) {
    final decoded = JwtDecoder.decode(token);
    final rolesField = decoded['roles'];
    if (rolesField is List) {
      return rolesField.map((role) => role.toString()).toList();
    }
    if (rolesField is String) {
      return [rolesField];
    }
    return [];
  }

  Future<void> _updateBackup(int backupId, BackupRestore updatedBackup) async {
    if (!mounted || !_isAdmin) return;

    setState(() => isLoading.value = true);

    if (!await _ensureApiInitialized()) {
      ErrorHandler.showError(Exception('未登录，请重新登录'),
          fallbackMessage: '未登录，请重新登录');
      setState(() => isLoading.value = false);
      return;
    }

    try {
      final idempotencyKey = generateIdempotencyKey();
      final payload = updatedBackup.copyWith(idempotencyKey: idempotencyKey);
      final result = await _backupApi.updateBackup(
        backupId: backupId,
        backupRestore: payload,
        idempotencyKey: idempotencyKey,
      );

      Get.snackbar('成功', '备份更新成功', snackPosition: SnackPosition.BOTTOM);
      setState(() {
        _backup = result;
        isLoading.value = false;
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => isLoading.value = false);
      ErrorHandler.showError(e,
          fallbackMessage: '更新备份失败: ${_formatErrorMessage(e)}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppException) {
      final message = error.message.isNotEmpty ? error.message : '服务器错误';
      return '$message (HTTP ${error.code})';
    }
    return error.toString();
  }

  // Helper method to format DateTime to a readable string
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return DashboardPageTemplate(
        theme: Theme.of(context),
        title: '备份详情',
        pageType: DashboardPageType.manager,
        isLoading: isLoading.value,
        errorMessage: isLoading.value ? null : '权限不足：仅管理员可访问此页面',
        body: const SizedBox.shrink(),
      );
    }

    return DashboardPageTemplate(
      theme: Theme.of(context),
      title: '备份详情',
      pageType: DashboardPageType.manager,
      bodyIsScrollable: true,
      padding: EdgeInsets.zero,
      actions: [
        DashboardPageBarAction(
          icon: Icons.edit,
          onPressed: () => _showUpdateBackupDialog(_backup),
          tooltip: '编辑备份',
        ),
      ],
      isLoading: isLoading.value,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading.value
            ? const LoadingView()
            : ListView(
                children: [
                  _buildDetailRow(
                      context, '备份 ID', _backup.backupId?.toString() ?? '无'),
                  _buildDetailRow(
                      context, '文件名', _backup.backupFileName ?? '无'),
                  _buildDetailRow(
                      context, '备份时间', _formatDateTime(_backup.backupTime)),
                  _buildDetailRow(
                      context, '恢复时间', _formatDateTime(_backup.restoreTime)),
                  _buildDetailRow(
                      context, '恢复状态', _backup.restoreStatus ?? '未恢复'),
                  _buildDetailRow(context, '备注', _backup.remarks ?? '无'),
                  _buildDetailRow(
                      context, '幂等键', _backup.idempotencyKey ?? '无'),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateBackupDialog(BackupRestore backup) {
    final TextEditingController fileNameController =
        TextEditingController(text: backup.backupFileName ?? '');
    final TextEditingController remarksController =
        TextEditingController(text: backup.remarks ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑备份'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: const InputDecoration(labelText: '文件名'),
              ),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final String fileName = fileNameController.text.trim();
              final String remarks = remarksController.text.trim();

              if (fileName.isEmpty) {
                _showSnackBar('文件名不能为空');
                return;
              }

              final updatedBackup = backup.copyWith(
                backupFileName: fileName,
                remarks: remarks,
              );

              _updateBackup(backup.backupId!, updatedBackup);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
