import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() =>
      _AppealManagementAdminPageState();
}

class _AppealManagementAdminPageState extends State<AppealManagementAdmin> {
  late Future<List<Appeal>> _appealsFuture;
  late RestApiServices _apiServices;
  late MessageProvider _messageProvider;

  @override
  void initState() {
    super.initState();
    _apiServices = RestApiServices();
    _messageProvider = MessageProvider();
    _appealsFuture = _fetchAppeals();

    // Initialize WebSocket for real-time updates
    _apiServices.initWebSocket('/eventbus/appeals/ws', _messageProvider);
  }

  @override
  void dispose() {
    _apiServices.closeWebSocket();
    super.dispose();
  }

  Future<List<Appeal>> _fetchAppeals() async {
    final url =
        Uri.parse('${AppConfig.baseUrl}${AppConfig.appealManagementEndpoint}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> appealsJson = jsonDecode(response.body);
        return appealsJson.map((json) => Appeal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appeals');
      }
    } catch (e) {
      throw Exception('Failed to load appeals: $e');
    }
  }

  Future<void> _updateAppealStatus(int appealId, String newStatus) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.appealManagementEndpoint}/$appealId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'processStatus': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh data after successfully updating the status
        _refreshAppeals();
        _showSnackBar('申诉状态更新成功！');
      } else {
        _showSnackBar('更新申诉状态失败，请稍后重试。');
      }
    } catch (e) {
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // Ensure that the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _refreshAppeals() {
    setState(() {
      _appealsFuture = _fetchAppeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _messageProvider,
      child: Scaffold(
        appBar: AppBar(title: const Text('管理员端交通违法申诉管理')),
        body: FutureBuilder<List<Appeal>>(
          future: _appealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('加载申诉记录时发生错误: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('没有找到申诉记录'));
            } else {
              final appeals = snapshot.data!;
              return ListView.builder(
                itemCount: appeals.length,
                itemBuilder: (context, index) {
                  final appeal = appeals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      title: Text('申诉人: ${appeal.appellantName}'),
                      subtitle: Text(
                          '原因: ${appeal.appealReason}\n状态: ${appeal.processStatus}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == '批准' || value == '拒绝') {
                            // Show a snack bar to indicate the operation is in progress
                            _showSnackBar('正在更新申诉状态...');
                            // Update the appeal status
                            _updateAppealStatus(appeal.appealId, value);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return ['批准', '拒绝'].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class Appeal {
  final int appealId;
  final String appellantName;
  final String appealReason;
  final String processStatus;

  Appeal({
    required this.appealId,
    required this.appellantName,
    required this.appealReason,
    required this.processStatus,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      appealId: json['appealId'],
      appellantName: json['appellantName'],
      appealReason: json['appealReason'],
      processStatus: json['processStatus'],
    );
  }
}
