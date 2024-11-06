import 'dart:convert';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';

/// 用户申诉页面 StatefulWidget
class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

/// 用户申诉页面状态管理
class _UserAppealPageState extends State<UserAppealPage> {
  late RestApiServices restApiServices;

  // 定义文本编辑控制器，用于搜索
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    // 初始化 WebSocket 连接，并传入 MessageProvider
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    restApiServices.initWebSocket(
        AppConfig.appealManagementEndpoint, messageProvider);

    // 发送获取申诉信息的请求
    restApiServices.sendMessage(jsonEncode({'action': 'getAppeals'}));
  }

  @override
  void dispose() {
    // 关闭 WebSocket 连接
    restApiServices.closeWebSocket();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户申述管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // 搜索区域
            SearchSection(
              searchController: _searchController,
            ),
            const SizedBox(height: 16),
            // 申述记录列表
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  final message = messageProvider.message;
                  if (message != null &&
                      (message.action == 'getAppealsResponse' ||
                          message.action == 'searchAppealsResponse')) {
                    if (message.data['status'] == 'success') {
                      List<AppealRecord> appealRecords =
                          List<AppealRecord>.from(
                        message.data['data']
                            .map((item) => AppealRecord.fromJson(item)),
                      );
                      return AppealRecordList(appealRecords: appealRecords);
                    } else {
                      return Center(
                        child: Text('加载申诉信息失败: ${message.data['message']}'),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 处理添加申诉的逻辑
          // 您可以导航到添加申诉的页面
        },
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 搜索区域组件
class SearchSection extends StatelessWidget {
  final TextEditingController searchController;

  const SearchSection({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: '请输入申述ID或车牌号',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // 处理查询点击事件
            String query = searchController.text;

            // 发送查询请求
            RestApiServices().sendMessage(
              jsonEncode({
                'action': 'searchAppeals',
                'query': query,
              }),
            );
          },
          child: const Text('查询'),
        ),
      ],
    );
  }
}

/// 申述记录列表组件
class AppealRecordList extends StatelessWidget {
  final List<AppealRecord> appealRecords;

  const AppealRecordList({super.key, required this.appealRecords});

  @override
  Widget build(BuildContext context) {
    if (appealRecords.isEmpty) {
      return const Center(
        child: Text('没有找到申诉记录'),
      );
    }
    return ListView.builder(
      itemCount: appealRecords.length,
      itemBuilder: (context, index) {
        final record = appealRecords[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 4,
          child: ListTile(
            title: Text('申述ID: ${record.id}'),
            subtitle:
                Text('车牌号: ${record.plateNumber}\n申述理由: ${record.reason}'),
            trailing: Text(record.status),
            onTap: () {
              // 您可以在这里处理点击事件，例如查看申诉详情
            },
          ),
        );
      },
    );
  }
}

/// 申述记录模型
class AppealRecord {
  int id;
  String plateNumber;
  String reason;
  String status;

  AppealRecord({
    required this.id,
    required this.plateNumber,
    required this.reason,
    required this.status,
  });

  factory AppealRecord.fromJson(Map<String, dynamic> json) {
    return AppealRecord(
      id: json['id'],
      plateNumber: json['plateNumber'],
      reason: json['reason'],
      status: json['status'],
    );
  }
}
