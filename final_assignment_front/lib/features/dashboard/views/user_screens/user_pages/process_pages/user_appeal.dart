import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 用户申诉页面 StatefulWidget
class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

/// 用户申诉页面状态管理
class _UserAppealPageState extends State<UserAppealPage>
    with SearchSectionMixin, AppealRecordListMixin, AppealFormMixin {
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

    // 发送获取所有申诉信息的请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      restApiServices.sendMessage(jsonEncode({'action': 'getAllAppeals'}));
    });
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
        title: const Text('用户申诉管理'),
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
            buildSection(restApiServices),
            const SizedBox(height: 16),
            // 申诉记录列表
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  final message = messageProvider.message;
                  if (message != null &&
                      (message.action == 'getAllAppealsResponse' ||
                          message.action == 'searchAppealsResponse')) {
                    if (message.data['status'] == 'success') {
                      List<AppealRecord> appealRecords =
                          List<AppealRecord>.from(
                        message.data['data']
                            .map((item) => AppealRecord.fromJson(item)),
                      );
                      return buildAppealRecordList(
                        appealRecords: appealRecords,
                        restApiServices: restApiServices, // 传递 restApiServices
                      );
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
          // 打开申诉添加页面
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('添加新的申诉'),
                content:
                    buildAppealForm(context, restApiServices: restApiServices),
              );
            },
          );
        },
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 搜索区域组件 Mixin
mixin SearchSectionMixin<T extends StatefulWidget> on State<T> {
  Widget buildSection(RestApiServices restApiServices) {
    final searchController = TextEditingController();

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: '请输入申诉ID或车牌号',
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

            restApiServices.sendMessage(
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

/// 申诉记录列表组件 Mixin
mixin AppealRecordListMixin<T extends StatefulWidget> on State<T> {
  Widget buildAppealRecordList({
    required List<AppealRecord> appealRecords,
    required RestApiServices restApiServices, // 传递 restApiServices 以便使用
  }) {
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
            title: Text('申诉ID: ${record.appealId}'),
            subtitle: Text(
                '车牌号: ${record.plateNumber}\n申诉理由: ${record.appealReason}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // 打开编辑申诉表单
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('编辑申诉信息'),
                          content: (this as AppealFormMixin).buildAppealForm(
                            context,
                            restApiServices: restApiServices,
                            // 传递 restApiServices
                            existingRecord: record,
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // 删除申诉信息
                    restApiServices.sendMessage(
                      jsonEncode({
                        'action': 'deleteAppeal',
                        'appealId': record.appealId,
                      }),
                    );

                    // 刷新数据
                    restApiServices
                        .sendMessage(jsonEncode({'action': 'getAllAppeals'}));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 申诉表单逻辑 Mixin
mixin AppealFormMixin<T extends StatefulWidget> on State<T> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _contactController = TextEditingController();
  final _reasonController = TextEditingController();

  Widget buildAppealForm(
    BuildContext appealContext, {
    required RestApiServices restApiServices,
    AppealRecord? existingRecord,
  }) {
    // 如果是编辑已有记录，填充控制器中的内容
    if (existingRecord != null) {
      _plateNumberController.text = existingRecord.plateNumber;
      _nameController.text = existingRecord.appellantName;
      _idCardController.text = existingRecord.idCardNumber;
      _contactController.text = existingRecord.contactNumber;
      _reasonController.text = existingRecord.appealReason;
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _plateNumberController,
              decoration: const InputDecoration(labelText: '车牌号'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入车牌号';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '申诉人姓名'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _idCardController,
              decoration: const InputDecoration(labelText: '身份证号'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入身份证号';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: '联系电话'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入联系电话';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: '申诉理由'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入申诉理由';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final appealId = existingRecord?.appealId ?? 0;

                  // 创建或更新申诉
                  restApiServices.sendMessage(
                    jsonEncode({
                      'action': appealId == 0 ? 'createAppeal' : 'updateAppeal',
                      'appealId': appealId,
                      'plateNumber': _plateNumberController.text,
                      'appellantName': _nameController.text,
                      'idCardNumber': _idCardController.text,
                      'contactNumber': _contactController.text,
                      'appealReason': _reasonController.text,
                    }),
                  );

                  Navigator.pop(context); // 提交后关闭表单

                  // 刷新数据
                  restApiServices
                      .sendMessage(jsonEncode({'action': 'getAllAppeals'}));
                }
              },
              child: Text(existingRecord == null ? '提交申诉' : '更新申诉'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用户申诉记录模型
class AppealRecord {
  int appealId;
  String plateNumber;
  String appellantName;
  String idCardNumber;
  String contactNumber;
  String appealReason;
  String appealTime;
  String processStatus;
  String processResult;

  AppealRecord({
    required this.appealId,
    required this.plateNumber,
    required this.appellantName,
    required this.idCardNumber,
    required this.contactNumber,
    required this.appealReason,
    required this.appealTime,
    required this.processStatus,
    required this.processResult,
  });

  factory AppealRecord.fromJson(Map<String, dynamic> json) {
    return AppealRecord(
      appealId: json['appealId'],
      plateNumber: json['plateNumber'],
      appellantName: json['appellantName'],
      idCardNumber: json['idCardNumber'],
      contactNumber: json['contactNumber'],
      appealReason: json['appealReason'],
      appealTime: json['appealTime'],
      processStatus: json['processStatus'],
      processResult: json['processResult'],
    );
  }
}
