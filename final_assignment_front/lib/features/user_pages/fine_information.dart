import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage> {
  late RestApiServices restApiServices;
  List<FineRecord> _fineRecords = [];

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();
    restApiServices.initWebSocket(AppConfig.fineInformationEndpoint);
    _loadFineData();
  }

  Future<void> _loadFineData() async {
    try {
      restApiServices.sendMessage(jsonEncode({'action': 'getFineInfo'}));
      final response = await restApiServices.getMessages().firstWhere((message) {
        final decodedMessage = jsonDecode(message);
        return decodedMessage['action'] == 'getFineInfoResponse';
      });

      final decodedMessage = jsonDecode(response);
      if (decodedMessage['status'] == 'success') {
        setState(() {
          _fineRecords = List<FineRecord>.from(
              decodedMessage['data'].map((item) => FineRecord.fromJson(item)));
        });
      } else {
        debugPrint('加载罚款信息失败: ${decodedMessage['message']}');
      }
    } catch (e) {
      debugPrint('加载罚款信息失败: $e');
    }
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
            const SearchSection(),
            const SizedBox(height: 16),
            // 罚款记录列表
            Expanded(
              child: FineRecordList(fineRecords: _fineRecords),
            ),
          ],
        ),
      ),
    );
  }
}

// 搜索区域
class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: '请输入车牌号',
              prefixIcon: Icon(Icons.local_bar),
            ),
            onChanged: (value) {
              // 更新搜索的车牌号
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: '选择查询时间',
              prefixIcon: Icon(Icons.date_range),
            ),
            onChanged: (value) {
              // 更新搜索的时间
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

// 罚款记录列表
class FineRecordList extends StatelessWidget {
  final List<FineRecord> fineRecords;

  const FineRecordList({super.key, required this.fineRecords});

  @override
  Widget build(BuildContext context) {
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
