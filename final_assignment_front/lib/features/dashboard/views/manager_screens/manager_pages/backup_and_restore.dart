import 'package:final_assignment_front/features/api/backup_restore_controller_api.dart';
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  // 可以使用 UUID 或其他方式生成唯一键
  return DateTime
      .now()
      .millisecondsSinceEpoch
      .toString();
}

/// 备份与恢复管理页面
class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({super.key});

  @override
  State<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  // 使用 BackupRestoreControllerApi 来发起HTTP请求
  late BackupRestoreControllerApi backupApi;

  // 用于展示在页面上的备份列表
  late Future<List<BackupRestore>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    // 初始化时创建 Api 实例
    backupApi = BackupRestoreControllerApi();
    // 加载所有备份
    _backupsFuture = _fetchAllBackups();
  }

  /// 获取所有备份
  Future<List<BackupRestore>> _fetchAllBackups() async {
    try {
      // 1) 调用 apiBackupsGet() 获取 (返回类型: Future<Object?>)
      final result = await backupApi.apiBackupsGet();
      if (result == null) {
        return [];
      }
      // 如果后端返回的是一个List<Object>，需要将其中每个Object转为Map<String,dynamic>，再构造BackupRestore
      if (result is List) {
        // 将 listOf dynamic -> List<BackupRestore>
        final backups = result.map((item) {
          final br = BackupRestore.fromJson(item as Map<String, dynamic>);
          return BackupRestore(
            backupId: br.backupId ?? 0,
            backupFileName: br.backupFileName ?? '',
            backupTime: br.backupTime ?? '',
            restoreTime: br.restoreTime ?? '',
            restoreStatus: br.restoreStatus ?? '',
            remarks: br.remarks ?? '',
            idempotencyKey: br.idempotencyKey ?? '',
          );
        }).toList();
        return backups;
      } else {
        // 如果后端返回的不是数组，比如是单个对象或其他结构，就自行处理
        return [];
      }
    } catch (e) {
      debugPrint('[BackupAndRestore] 获取所有备份失败: $e');
      _showSnackBar('加载备份列表失败: $e');
      return [];
    }
  }

  /// 创建备份
  Future<void> _createBackup() async {
    try {
      // 1) 生成备份文件名
      final backupName = 'backup_${DateTime.now().toIso8601String()}';

      // 2) 生成一个幂等键
      final uniqueKey = generateIdempotencyKey();

      // 3) 构造一个 BackupRestore 对象，包含所有必填字段
      final newBackup = BackupRestore(
        backupId: null,
        // 表示还没有实际 ID
        backupFileName: backupName,
        backupTime: DateTime.now().toIso8601String(),
        restoreTime: '',
        restoreStatus: '',
        remarks: '手动创建的备份',
        idempotencyKey: uniqueKey, // 幂等键
      );

      // 4) 调用 POST /api/backups
      final result = await backupApi.apiBackupsPost(backupRestore: newBackup);

      // 5) 处理结果
      if (result is Map<String, dynamic>) {
        if (result['status'] == 'success') {
          _showSnackBar('备份创建成功！');
          // 刷新列表
          setState(() {
            _backupsFuture = _fetchAllBackups();
          });
        } else if (result['status'] == 'duplicate') {
          // 后端可能返回特定字段表示重复
          _showSnackBar(
              '备份创建重复：${result['message'] ?? '已存在相同的备份请求'}');
        } else {
          _showSnackBar('备份创建失败：${result['message'] ?? '未知错误'}');
        }
      } else {
        _showSnackBar('备份创建失败：响应格式错误');
      }
    } on ApiException catch (e) {
      if (e.code == 409) {
        // 409 Conflict 表示重复请求
        _showSnackBar('备份创建重复：${e.message}');
      } else {
        _showSnackBar('备份创建失败: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('创建备份失败: $e');
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup(int backupId) async {
    try {
      // 生成一个幂等键
      final uniqueKey = generateIdempotencyKey();

      // 构造请求体，根据后端需求调整
      final restoreRequest = {
        'backupNumber': backupId,
        'idempotencyKey': uniqueKey,
      };

      // 假设后端有一个恢复备份的端点，接受 PUT 请求
      final result = await backupApi.apiBackupsBackupIdPut(
        backupId.toString(),
        backupNumber: backupId, // 根据实际 API 调整
      );

      // 处理结果
      if (result is Map<String, dynamic>) {
        if (result['status'] == 'success') {
          _showSnackBar('恢复备份成功！');
          // 刷新列表
          setState(() {
            _backupsFuture = _fetchAllBackups();
          });
        } else if (result['status'] == 'duplicate') {
          _showSnackBar(
              '恢复备份请求重复：${result['message'] ?? '已恢复过此备份'}');
        } else {
          _showSnackBar('恢复备份失败：${result['message'] ?? '未知错误'}');
        }
      } else {
        _showSnackBar('恢复备份失败：响应格式错误');
      }
    } on ApiException catch (e) {
      if (e.code == 409) {
        // 409 Conflict 表示重复请求
        _showSnackBar('恢复备份请求重复：${e.message}');
      } else {
        _showSnackBar('恢复备份失败: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('恢复备份失败: $e');
    }
  }

  /// 删除备份
  Future<void> _deleteBackup(int backupId) async {
    try {
      // 生成一个幂等键
      final uniqueKey = generateIdempotencyKey();

      // 构造请求体，根据后端需求调整
      final deleteRequest = {
        'idempotencyKey': uniqueKey,
      };

      // 调用 DELETE /api/backups/{backupId}
      final result =
      await backupApi.apiBackupsBackupIdDelete(backupId.toString());

      // 处理结果
      if (result == null) {
        // DELETE 成功，通常返回 204 No Content
        _showSnackBar('删除备份成功！');
        // 刷新列表
        setState(() {
          _backupsFuture = _fetchAllBackups();
        });
      } else {
        if (result is Map<String, dynamic>) {
          if (result['status'] == 'success') {
            _showSnackBar('删除备份成功！');
            setState(() {
              _backupsFuture = _fetchAllBackups();
            });
          } else if (result['status'] == 'duplicate') {
            _showSnackBar(
                '删除备份请求重复：${result['message'] ?? '已删除过此备份'}');
          } else {
            _showSnackBar('删除备份失败：${result['message'] ?? '未知错误'}');
          }
        } else {
          _showSnackBar('删除备份失败：响应格式错误');
        }
      }
    } on ApiException catch (e) {
      if (e.code == 409) {
        _showSnackBar('删除备份请求重复：${e.message}');
      } else {
        _showSnackBar('删除备份失败: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('删除备份失败: $e');
    }
  }

  /// 根据文件名搜索
  Future<void> _fetchBackupsByFileName(String fileName) async {
    if (fileName.isEmpty) {
      setState(() {
        _backupsFuture = _fetchAllBackups();
      });
      return;
    }
    try {
      final result =
      await backupApi.apiBackupsFilenameBackupFileNameGet(fileName);
      if (result == null) {
        _showSnackBar('未找到匹配的备份(空返回)。');
        return;
      }
      // 如果后端是单条返回 => result is Map => 转为1条
      if (result is Map<String, dynamic>) {
        final br = BackupRestore.fromJson(result);
        final single = BackupRestore(
          backupId: br.backupId ?? 0,
          backupFileName: br.backupFileName ?? '',
          backupTime: br.backupTime ?? '',
          restoreTime: br.restoreTime ?? '',
          restoreStatus: br.restoreStatus ?? '',
          remarks: br.remarks ?? '',
          idempotencyKey: br.idempotencyKey ?? '',
        );
        setState(() {
          _backupsFuture = Future.value([single]);
        });
      } else if (result is List) {
        // 如果后端返回多条 => List
        final list = result.map((item) {
          final br = BackupRestore.fromJson(item as Map<String, dynamic>);
          return BackupRestore(
            backupId: br.backupId ?? 0,
            backupFileName: br.backupFileName ?? '',
            backupTime: br.backupTime ?? '',
            restoreTime: br.restoreTime ?? '',
            restoreStatus: br.restoreStatus ?? '',
            remarks: br.remarks ?? '',
            idempotencyKey: br.idempotencyKey ?? '',
          );
        }).toList();
        setState(() {
          _backupsFuture = Future.value(list);
        });
      } else {
        _showSnackBar('未知返回格式：$result');
      }
    } catch (e) {
      _showSnackBar('按文件名搜索备份失败: $e');
    }
  }

  /// 根据时间搜索
  Future<void> _fetchBackupsByTime(String backupTime) async {
    if (backupTime.isEmpty) {
      setState(() {
        _backupsFuture = _fetchAllBackups();
      });
      return;
    }
    try {
      final result = await backupApi.apiBackupsTimeBackupTimeGet(backupTime);
      if (result == null) {
        _showSnackBar('未找到匹配的备份(空返回)。');
        return;
      }
      if (result is List) {
        final list = result.map((item) {
          final br = BackupRestore.fromJson(item as Map<String, dynamic>);
          return BackupRestore(
            backupId: br.backupId ?? 0,
            backupFileName: br.backupFileName ?? '',
            backupTime: br.backupTime ?? '',
            restoreTime: br.restoreTime ?? '',
            restoreStatus: br.restoreStatus ?? '',
            remarks: br.remarks ?? '',
            idempotencyKey: br.idempotencyKey ?? '',
          );
        }).toList();
        setState(() {
          _backupsFuture = Future.value(list);
        });
      } else if (result is Map<String, dynamic>) {
        // 如果后端返回单条
        final br = BackupRestore.fromJson(result);
        final single = BackupRestore(
          backupId: br.backupId ?? 0,
          backupFileName: br.backupFileName ?? '',
          backupTime: br.backupTime ?? '',
          restoreTime: br.restoreTime ?? '',
          restoreStatus: br.restoreStatus ?? '',
          remarks: br.remarks ?? '',
          idempotencyKey: br.idempotencyKey ?? '',
        );
        setState(() {
          _backupsFuture = Future.value([single]);
        });
      } else {
        _showSnackBar('未知返回格式：$result');
      }
    } catch (e) {
      _showSnackBar('按时间搜索备份失败: $e');
    }
  }

  /// 显示 SnackBar 消息
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 构建备份列表项
  Widget _buildBackupItem(BackupRestore backup) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text('文件名: ${backup.backupFileName}'),
        subtitle: Text('备份时间: ${backup.backupTime}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () => _restoreBackup(backup.backupId!),
              tooltip: '恢复此备份',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBackup(backup.backupId!),
              tooltip: '删除此备份',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份与恢复管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createBackup,
            tooltip: '创建新备份',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 按文件名搜索
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '按文件名搜索备份',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) =>
                        _fetchBackupsByFileName(value.trim()),
                  ),
                ),
                const SizedBox(width: 8.0),
                // 按时间搜索
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '按备份时间搜索',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        // 你后端 backupTime 格式若是 yyyy-MM-dd 这种，则需格式化
                        String formatted =
                            "${pickedDate.year.toString().padLeft(
                            4, '0')}-${pickedDate.month.toString().padLeft(
                            2, '0')}-${pickedDate.day.toString().padLeft(
                            2, '0')}";
                        _fetchBackupsByTime(formatted);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: FutureBuilder<List<BackupRestore>>(
              future: _backupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('加载备份记录时发生错误: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到备份记录'));
                } else {
                  final backups = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _backupsFuture = _fetchAllBackups();
                      });
                    },
                    child: ListView.builder(
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return _buildBackupItem(backup);
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
