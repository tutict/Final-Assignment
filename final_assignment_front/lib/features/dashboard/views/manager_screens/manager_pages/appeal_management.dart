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
    _appealsFuture = _fetchAllAppeals();

    // Initialize WebSocket for real-time updates
    _apiServices.initWebSocket(
        AppConfig.appealManagementEndpoint, _messageProvider);
  }

  @override
  void dispose() {
    _apiServices.closeWebSocket();
    super.dispose();
  }

  Future<List<Appeal>> _fetchAllAppeals() async {
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

  Future<void> _fetchAppealsByStatus(String status) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.appealManagementEndpoint}/status/$status');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> appealsJson = jsonDecode(response.body);
        setState(() {
          _appealsFuture = Future.value(
              appealsJson.map((json) => Appeal.fromJson(json)).toList());
        });
      } else {
        _showSnackBar('获取申诉记录失败');
      }
    } catch (e) {
      _showSnackBar('发生错误，请检查网络连接');
    }
  }

  Future<void> _updateAppeal(int appealId, Appeal updatedAppeal) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.appealManagementEndpoint}/$appealId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedAppeal.toJson()),
      );

      if (response.statusCode == 200) {
        // Refresh data after successfully updating the appeal
        _refreshAppeals();
        _showSnackBar('申诉信息更新成功！');
      } else {
        _showSnackBar('更新申诉信息失败，请稍后重试。');
      }
    } catch (e) {
      _showSnackBar('发生错误，请检查网络连接。');
    }
  }

  Future<void> _deleteAppeal(int appealId) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.appealManagementEndpoint}/$appealId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 204) {
        _refreshAppeals();
        _showSnackBar('申诉删除成功！');
      } else {
        _showSnackBar('删除申诉失败，请稍后重试。');
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
      _appealsFuture = _fetchAllAppeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _messageProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('管理员端交通违法申诉管理'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                // 根据选中的状态获取申诉列表
                _fetchAppealsByStatus(value);
              },
              itemBuilder: (context) {
                return ['全部', '处理中', '已批准', '已拒绝'].map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
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
                            _showSnackBar('正在更新申诉状态...');
                            _updateAppeal(
                                appeal.appealId,
                                appeal.copyWith(
                                  processStatus: value,
                                ));
                          } else if (value == '删除') {
                            _deleteAppeal(appeal.appealId);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return ['批准', '拒绝', '删除'].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                      onTap: () {
                        // 打开申诉详细信息页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AppealDetailPage(appeal: appeal)),
                        );
                      },
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

  Map<String, dynamic> toJson() {
    return {
      'appealId': appealId,
      'appellantName': appellantName,
      'appealReason': appealReason,
      'processStatus': processStatus,
    };
  }

  Appeal copyWith({
    int? appealId,
    String? appellantName,
    String? appealReason,
    String? processStatus,
  }) {
    return Appeal(
      appealId: appealId ?? this.appealId,
      appellantName: appellantName ?? this.appellantName,
      appealReason: appealReason ?? this.appealReason,
      processStatus: processStatus ?? this.processStatus,
    );
  }
}

class AppealDetailPage extends StatelessWidget {
  final Appeal appeal;

  const AppealDetailPage({super.key, required this.appeal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('申诉人: ${appeal.appellantName}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('原因: ${appeal.appealReason}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('状态: ${appeal.processStatus}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
