import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'dart:convert';

/// 用户申诉页面 StatefulWidget
class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

/// 用户申诉页面状态管理
class _UserAppealPageState extends State<UserAppealPage> {
  late RestApiServices restApiServices;
  List<AppealRecord> _appealRecords = [];

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();
    restApiServices.initWebSocket(AppConfig.appealManagementEndpoint);
    _loadAppealData();
  }

  /// 加载申诉数据
  Future<void> _loadAppealData() async {
    try {
      restApiServices.sendMessage(jsonEncode({'action': 'getAppeals'}));
      final response =
      await restApiServices.getMessages().firstWhere((message) {
        final decodedMessage = jsonDecode(message);
        return decodedMessage['action'] == 'getAppealsResponse';
      });

      final decodedMessage = jsonDecode(response);
      if (decodedMessage['status'] == 'success') {
        setState(() {
          _appealRecords = List<AppealRecord>.from(decodedMessage['data']
              .map((item) => AppealRecord.fromJson(item)));
        });
      } else {
        debugPrint('加载申诉信息失败: ${decodedMessage['message']}');
      }
    } catch (e) {
      debugPrint('加载申诉信息失败: $e');
    }
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
            const SearchSection(),
            const SizedBox(height: 16),
            // 申述记录列表
            Expanded(
              child: AppealRecordList(appealRecords: _appealRecords),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 搜索区域组件
class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: '请输入申述ID或车牌号',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // 更新搜索的申述信息
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // 处理查询点击事件
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
