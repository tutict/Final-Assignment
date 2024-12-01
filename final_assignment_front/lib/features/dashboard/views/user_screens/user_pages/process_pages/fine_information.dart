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

class _FineInformationPageState extends State<FineInformationPage> {
  late RestApiServices restApiServices;

  // 控制器
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _fineAmountController = TextEditingController();
  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _receiptNumberController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

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
    restApiServices.closeWebSocket();
    super.dispose();
  }

  // 提交罚款信息的函数
  void submitFineInfo() {
    String plateNumber = _plateNumberController.text;
    double fineAmount = double.tryParse(_fineAmountController.text) ?? 0.0;
    String payee = _payeeController.text;
    String accountNumber = _accountNumberController.text;
    String bank = _bankController.text;
    String receiptNumber = _receiptNumberController.text;
    String remarks = _remarksController.text;
    String date = _dateController.text;

    // 发送罚款记录
    restApiServices.sendMessage(jsonEncode({
      'action': 'submitFineInfo',
      'plateNumber': plateNumber,
      'fineAmount': fineAmount,
      'payee': payee,
      'accountNumber': accountNumber,
      'bank': bank,
      'receiptNumber': receiptNumber,
      'remarks': remarks,
      'fineTime': date,
    }));

    // 清空表单
    _plateNumberController.clear();
    _fineAmountController.clear();
    _payeeController.clear();
    _accountNumberController.clear();
    _bankController.clear();
    _receiptNumberController.clear();
    _remarksController.clear();
    _dateController.clear();
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
            buildSearchSection(),
            const SizedBox(height: 16),
            // 罚款记录输入表单
            buildFineInfoForm(),
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

  Widget buildSearchSection() {
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
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
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
            String plateNumber = plateNumberController.text;
            String date = dateController.text;

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

  Widget buildFineInfoForm() {
    return Column(
      children: [
        TextField(
          controller: _plateNumberController,
          decoration: const InputDecoration(
            labelText: '车牌号',
            prefixIcon: Icon(Icons.local_bar),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _fineAmountController,
          decoration: const InputDecoration(
            labelText: '罚款金额',
            prefixIcon: Icon(Icons.money),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _payeeController,
          decoration: const InputDecoration(
            labelText: '收款人',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNumberController,
          decoration: const InputDecoration(
            labelText: '账户号码',
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bankController,
          decoration: const InputDecoration(
            labelText: '银行',
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _receiptNumberController,
          decoration: const InputDecoration(
            labelText: '收据号码',
            prefixIcon: Icon(Icons.receipt),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          decoration: const InputDecoration(
            labelText: '备注',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: '罚款日期',
            prefixIcon: Icon(Icons.date_range),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              _dateController.text = pickedDate.toString().split(' ')[0];
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: submitFineInfo,
          child: const Text('提交罚款信息'),
        ),
      ],
    );
  }

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

// 用户罚款记录模型
class FineRecord {
  int id;
  String plateNumber;
  double fineAmount;
  String payee;
  String accountNumber;
  String bank;
  String receiptNumber;
  String remarks;
  String date;

  FineRecord({
    required this.id,
    required this.plateNumber,
    required this.fineAmount,
    required this.payee,
    required this.accountNumber,
    required this.bank,
    required this.receiptNumber,
    required this.remarks,
    required this.date,
  });

  factory FineRecord.fromJson(Map<String, dynamic> json) {
    return FineRecord(
      id: json['fineId'],
      plateNumber: json['plateNumber'],
      fineAmount: json['fineAmount'],
      payee: json['payee'],
      accountNumber: json['accountNumber'],
      bank: json['bank'],
      receiptNumber: json['receiptNumber'],
      remarks: json['remarks'],
      date: json['fineTime'],
    );
  }
}
