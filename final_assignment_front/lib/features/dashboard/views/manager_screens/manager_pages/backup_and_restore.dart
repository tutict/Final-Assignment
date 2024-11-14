import 'dart:convert';

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
        Uri.parse('\${AppConfig.baseUrl}\${AppConfig.backupRestoreEndpoint}');
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
      throw Exception('Failed to load backups: \$e');
    }
  }

  Future<void> _createBackup() async {
    final url =
        Uri.parse('\${AppConfig.baseUrl}\${AppConfig.backupRestoreEndpoint}');
    try {
      final response = await http.post(url);
      if (!mounted) return;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份创建成功！')),
        );
        setState(() {
          _backupsFuture = _fetchBackups(); // Refresh the data
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建备份失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  Future<void> _restoreBackup(int backupId) async {
    final url = Uri.parse(
        '\${AppConfig.baseUrl}\${AppConfig.backupRestoreEndpoint}/\$backupId');
    try {
      final response = await http.put(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复备份成功！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复备份失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  Future<void> _deleteBackup(int backupId) async {
    final url = Uri.parse(
        '\${AppConfig.baseUrl}\${AppConfig.backupRestoreEndpoint}/\$backupId');
    try {
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除备份成功！')),
        );
        setState(() {
          _backupsFuture = _fetchBackups(); // Refresh the data
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除备份失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
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
      body: FutureBuilder<List<Backup>>(
        future: _backupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('加载备份记录时发生错误: \${snapshot.error}'));
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
                    title: const Text('备份文件名: \${backup.backupFileName}'),
                    subtitle: const Text('备份时间: \${backup.backupTime}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () => _restoreBackup(backup.backupId),
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
