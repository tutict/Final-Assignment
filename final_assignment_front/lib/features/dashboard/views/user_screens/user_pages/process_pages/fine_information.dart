import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage>
    with SearchMixin, FineRecordListMixin {
  late RestApiServices restApiServices;

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    // 初始化 WebSocket 连接，并传入 MessageProvider
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    restApiServices.initWebSocket(
        AppConfig.fineInformationEndpoint, messageProvider);

    // 发送获取罚款信息的请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      restApiServices.sendMessage(jsonEncode({'action': 'getFineInfo'}));
    });
  }

  @override
  void dispose() {
    // 关闭 WebSocket 连接
    restApiServices.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交通违法罚款记录'),
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
            buildSearchSection(restApiServices),
            const SizedBox(height: 16),
            // 罚款记录列表
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  final message = messageProvider.message;
                  if (message != null &&
                      message.action == 'getFineInfoResponse') {
                    if (message.data['status'] == 'success') {
                      List<FineRecord> fineRecords = List<FineRecord>.from(
                        message.data['data']
                            .map((item) => FineRecord.fromJson(item)),
                      );
                      return buildFineRecordList(fineRecords: fineRecords);
                    } else {
                      return Center(
                        child: Text('加载罚款信息失败: ${message.data['message']}'),
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
    );
  }
}

mixin SearchMixin<T extends StatefulWidget> on State<T> {
  Widget buildSearchSection(RestApiServices restApiServices) {
    // 定义文本编辑控制器
    final plateNumberController = TextEditingController();
    final dateController = TextEditingController();

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: plateNumberController,
            decoration: const InputDecoration(
              labelText: '请输入车牌号',
              prefixIcon: Icon(Icons.local_bar),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: dateController,
            decoration: const InputDecoration(
              labelText: '选择查询时间',
              prefixIcon: Icon(Icons.date_range),
            ),
            onTap: () async {
              // 选择日期
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(), // 初始日期
                firstDate: DateTime(2000), // 起始日期
                lastDate: DateTime(2101), // 结束日期
              );
              if (pickedDate != null) {
                dateController.text = pickedDate.toString().split(' ')[0];
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // 处理查询点击事件
            String plateNumber = plateNumberController.text;
            String date = dateController.text;

            // 发送查询请求
            restApiServices.sendMessage(
              jsonEncode({
                'action': 'searchFineInfo',
                'plateNumber': plateNumber,
                'date': date,
              }),
            );
          },
          child: const Text('查询'),
        ),
      ],
    );
  }
}

mixin FineRecordListMixin<T extends StatefulWidget> on State<T> {
  Widget buildFineRecordList({required List<FineRecord> fineRecords}) {
    return ListView.builder(
      itemCount: fineRecords.length,
      itemBuilder: (context, index) {
        final record = fineRecords[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(record.id.toString()),
          ),
          title: Text(record.plateNumber),
          subtitle: Text('罚款金额: ${record.fineAmount}元'),
          trailing: Text(record.date),
        );
      },
    );
  }
}

// 罚款记录模型
class FineRecord {
  int id;
  String plateNumber;
  int fineAmount;
  String date;

  FineRecord({
    required this.id,
    required this.plateNumber,
    required this.fineAmount,
    required this.date,
  });

  factory FineRecord.fromJson(Map<String, dynamic> json) {
    return FineRecord(
      id: json['id'],
      plateNumber: json['plateNumber'],
      fineAmount: json['fineAmount'],
      date: json['date'],
    );
  }
}
