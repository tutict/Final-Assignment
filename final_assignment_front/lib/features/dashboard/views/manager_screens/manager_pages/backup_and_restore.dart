import 'package:final_assignment_front/features/api/backup_restore_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 备份与恢复管理页面
class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({super.key});

  @override
  State<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  late BackupRestoreControllerApi backupApi;
  late Future<List<BackupRestore>> _backupsFuture;
  final DashboardController controller = Get.find<DashboardController>();
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _backupTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    backupApi = BackupRestoreControllerApi();
    _checkUserRole(); // 检查用户角色并加载备份
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _backupTimeController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/users/me'), // 后端地址
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final roleData = jsonDecode(response.body);
      final userRole = (roleData['roles'] as List<dynamic>).firstWhere(
        (role) => role == 'ADMIN',
        orElse: () => 'USER',
      );

      setState(() {
        _isAdmin = userRole == 'ADMIN';
        if (_isAdmin) {
          _loadBackups(); // 仅管理员加载所有备份
        } else {
          _errorMessage = '权限不足：仅管理员可访问此页面';
          _isLoading = false;
        }
      });
    } else {
      setState(() {
        _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
        _isLoading = false;
      });
    }
  }

  Future<List<BackupRestore>> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/backups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final backups =
            data.map((json) => BackupRestore.fromJson(json)).toList();
        setState(() {
          _backupsFuture = Future.value(backups);
          _isLoading = false;
        });
        return backups; // 返回 List<BackupRestore>
      } else {
        throw Exception('加载备份记录失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载备份记录失败: $e';
      });
      return []; // 发生错误时返回空列表
    }
  }

  Future<void> _searchBackups(String type, String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      Uri uri;
      if (type == 'filename' && query.isNotEmpty) {
        uri = Uri.parse('http://localhost:8081/api/backups/filename/$query');
      } else if (type == 'time' && query.isNotEmpty) {
        uri = Uri.parse('http://localhost:8081/api/backups/time/$query');
      } else {
        await _loadBackups();
        return;
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final backups = _parseBackupResult(data);
        setState(() {
          _backupsFuture = Future.value(backups);
          _isLoading = false;
        });
      } else {
        throw Exception('搜索失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索备份失败: $e';
      });
    }
  }

  Future<void> _createBackup() async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final backupName = 'backup_${DateTime.now().toIso8601String()}';
      final String idempotencyKey = generateIdempotencyKey();

      final newBackup = BackupRestore(
        backupId: null,
        backupFileName: backupName,
        backupTime: DateTime.now().toIso8601String(),
        restoreTime: null,
        restoreStatus: null,
        remarks: '手动创建的备份',
        idempotencyKey: idempotencyKey,
      );

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/backups?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(newBackup.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('备份创建成功！')),
        );
        _loadBackups(); // 刷新列表
      } else {
        final result = jsonDecode(response.body);
        if (result['status'] == 'duplicate') {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('备份创建重复：${result['message'] ?? '已存在相同的备份请求'}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('备份创建失败：${result['message'] ?? '未知错误'}')),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('创建备份失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _updateBackup(int backupId, BackupRestore updatedBackup) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      updatedBackup.idempotencyKey = idempotencyKey; // 更新幂等键

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/backups/$backupId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(updatedBackup.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('备份更新成功！')),
        );
        _loadBackups(); // 刷新列表
      } else {
        final result = jsonDecode(response.body);
        if (result['status'] == 'duplicate') {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('备份更新重复：${result['message'] ?? '已存在相同的更新请求'}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('备份更新失败：${result['message'] ?? '未知错误'}')),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新备份失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _restoreBackup(int backupId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/backups/$backupId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'restoreTime': DateTime.now().toIso8601String(),
          'restoreStatus': 'Restored',
          'idempotencyKey': idempotencyKey,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('恢复备份成功！')),
          );
          _loadBackups(); // 刷新列表
        } else if (result['status'] == 'duplicate') {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('恢复备份请求重复：${result['message'] ?? '已恢复过此备份'}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('恢复备份失败：${result['message'] ?? '未知错误'}')),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('恢复备份失败：响应格式错误')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('恢复备份失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _deleteBackup(int backupId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final response = await http.delete(
        Uri.parse(
            'http://localhost:8081/api/backups/$backupId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除备份成功！')),
        );
        _loadBackups(); // 刷新列表
      } else {
        final result = jsonDecode(response.body);
        if (result['status'] == 'duplicate') {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('删除备份请求重复：${result['message'] ?? '已删除过此备份'}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('删除备份失败：${result['message'] ?? '未知错误'}')),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除备份失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<BackupRestore> _parseBackupResult(dynamic result) {
    if (result == null) return [];
    if (result is List) {
      return result
          .map((item) => BackupRestore.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (result is Map<String, dynamic>) {
      return [BackupRestore.fromJson(result)];
    }
    return [];
  }

  void _goToDetailPage(BackupRestore backup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupDetailPage(backup: backup),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadBackups(); // 详情页更新后刷新列表
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

              final updatedBackup = BackupRestore(
                backupId: backup.backupId,
                backupFileName: fileName,
                backupTime: backup.backupTime,
                restoreTime: backup.restoreTime,
                restoreStatus: backup.restoreStatus,
                remarks: remarks,
                idempotencyKey: generateIdempotencyKey(),
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('备份与恢复管理'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createBackup,
                tooltip: '创建新备份',
              ),
            ],
          ),
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
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
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
                                    secondary: isLight
                                        ? Colors.blue
                                        : Colors.blueGrey),
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
                        backgroundColor:
                            isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (_errorMessage.isNotEmpty)
                  Expanded(child: Center(child: Text(_errorMessage)))
                else
                  Expanded(
                    child: FutureBuilder<List<BackupRestore>>(
                      future: _backupsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '加载备份记录时发生错误: ${snapshot.error}',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '没有找到备份记录',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        } else {
                          final backups = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadBackups,
                            // 直接返回 Future<List<BackupRestore>>
                            child: ListView.builder(
                              itemCount: backups.length,
                              itemBuilder: (context, index) {
                                final backup = backups[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color:
                                      isLight ? Colors.white : Colors.grey[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '文件名: ${backup.backupFileName}',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '备份时间: ${backup.backupTime}\n恢复时间: ${backup.restoreTime ?? '未恢复'}\n恢复状态: ${backup.restoreStatus ?? '未恢复'}',
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
                                              _restoreBackup(backup.backupId!),
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
                                              _showUpdateBackupDialog(backup),
                                          tooltip: '编辑此备份',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: isLight
                                                ? Colors.red
                                                : Colors.red[300],
                                          ),
                                          onPressed: () =>
                                              _deleteBackup(backup.backupId!),
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
                          );
                        }
                      },
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

class BackupDetailPage extends StatefulWidget {
  final BackupRestore backup;

  const BackupDetailPage({super.key, required this.backup});

  @override
  State<BackupDetailPage> createState() => _BackupDetailPageState();
}

class _BackupDetailPageState extends State<BackupDetailPage> {
  bool _isLoading = false;
  bool _isAdmin = false; // 管理员权限标识
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.backup.remarks ?? '';
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      }
    }
  }

  Future<void> _updateBackup(int backupId, BackupRestore updatedBackup) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      updatedBackup.idempotencyKey = idempotencyKey; // 更新幂等键

      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/backups/$backupId?idempotencyKey=$idempotencyKey'),
        // 后端需要幂等键作为查询参数
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(updatedBackup.toJson()),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('备份更新成功！')),
        );
        setState(() {
          widget.backup.backupFileName = updatedBackup.backupFileName;
          widget.backup.remarks = updatedBackup.remarks;
        });
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        final result = jsonDecode(response.body);
        if (result['status'] == 'duplicate') {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('备份更新重复：${result['message'] ?? '已存在相同的更新请求'}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('备份更新失败：${result['message'] ?? '未知错误'}')),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新备份失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    final backup = widget.backup;

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            '权限不足：仅管理员可访问此页面',
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          if (_isAdmin) // 仅 ADMIN 显示编辑按钮
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isLight ? Colors.white : Colors.white,
              ),
              onPressed: () => _showUpdateBackupDialog(widget.backup),
              tooltip: '编辑备份',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildDetailRow(
                      context, '备份 ID', backup.backupId?.toString() ?? '无'),
                  _buildDetailRow(context, '文件名', backup.backupFileName ?? '无'),
                  _buildDetailRow(context, '备份时间', backup.backupTime ?? '无'),
                  _buildDetailRow(context, '恢复时间', backup.restoreTime ?? '未恢复'),
                  _buildDetailRow(
                      context, '恢复状态', backup.restoreStatus ?? '未恢复'),
                  _buildDetailRow(context, '备注', backup.remarks ?? '无'),
                  _buildDetailRow(context, '幂等键', backup.idempotencyKey ?? '无'),
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

              final updatedBackup = BackupRestore(
                backupId: backup.backupId,
                backupFileName: fileName,
                backupTime: backup.backupTime,
                restoreTime: backup.restoreTime,
                restoreStatus: backup.restoreStatus,
                remarks: remarks,
                idempotencyKey: generateIdempotencyKey(),
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
