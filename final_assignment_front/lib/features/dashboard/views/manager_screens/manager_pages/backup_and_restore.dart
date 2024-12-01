import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({super.key});

  @override
  State<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  late Future<List<Backup>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _backupsFuture = _fetchBackups();
  }

  Future<List<Backup>> _fetchBackups() async {
    final url =
        Uri.parse('${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}');
    try {
      final response = await http.get(url);
      if (!mounted) return [];
      if (response.statusCode == 200) {
        List<dynamic> backupsJson = jsonDecode(response.body);
        return backupsJson.map((json) => Backup.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load backups');
      }
    } catch (e) {
      throw Exception('Failed to load backups: $e');
    }
  }

  Future<void> _createBackup() async {
    final url =
        Uri.parse('${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'backupFileName': 'backup_${DateTime.now().toIso8601String()}',
          // Example backup name
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _showSnackBar('备份创建成功！');
        setState(() {
          _backupsFuture = _fetchBackups(); // Refresh the data
        });
      } else {
        _showSnackBar('创建备份失败，请稍后重试。');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  Future<void> _restoreBackup(int backupId) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}/$backupId');
    try {
      final response = await http.put(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackBar('恢复备份成功！');
      } else {
        _showSnackBar('恢复备份失败，请稍后重试。');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  Future<void> _deleteBackup(int backupId) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}/$backupId');
    try {
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 204) {
        _showSnackBar('删除备份成功！');
        setState(() {
          _backupsFuture = _fetchBackups(); // Refresh the data
        });
      } else {
        _showSnackBar('删除备份失败，请稍后重试。');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _fetchBackupsByFileName(String fileName) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}/filename/$fileName');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        Backup backup = Backup.fromJson(jsonDecode(response.body));
        setState(() {
          _backupsFuture = Future.value([backup]);
        });
      } else {
        _showSnackBar('未找到匹配的备份。');
      }
    } catch (e) {
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  Future<void> _fetchBackupsByTime(String backupTime) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.backupRestoreEndpoint}/time/$backupTime');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        List<dynamic> backupsJson = jsonDecode(response.body);
        setState(() {
          _backupsFuture = Future.value(
              backupsJson.map((json) => Backup.fromJson(json)).toList());
        });
      } else {
        _showSnackBar('未找到匹配的备份。');
      }
    } catch (e) {
      _showSnackBar('发生错误，请检查网络连接。');
    }
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
          // Add a search section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '按文件名搜索备份',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _fetchBackupsByFileName(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
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
                        String formattedDate = pickedDate.toIso8601String();
                        _fetchBackupsByTime(formattedDate);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Backup list
          Expanded(
            child: FutureBuilder<List<Backup>>(
              future: _backupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('加载备份记录时发生错误: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到备份记录'));
                } else {
                  final backups = snapshot.data!;
                  return ListView.builder(
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('备份文件名: ${backup.backupFileName}'),
                          subtitle: Text('备份时间: ${backup.backupTime}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () =>
                                    _restoreBackup(backup.backupId),
                                tooltip: '恢复此备份',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteBackup(backup.backupId),
                                tooltip: '删除此备份',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class Backup {
  final int backupId;
  final String backupFileName;
  final String backupTime;

  Backup({
    required this.backupId,
    required this.backupFileName,
    required this.backupTime,
  });

  factory Backup.fromJson(Map<String, dynamic> json) {
    return Backup(
      backupId: json['backupId'],
      backupFileName: json['backupFileName'],
      backupTime: json['backupTime'],
    );
  }
}
