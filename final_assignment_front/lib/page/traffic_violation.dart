import 'package:flutter/material.dart';

class TrafficViolationManagementQueryPage extends StatefulWidget {
  @override
  _TrafficViolationManagementQueryPageState createState() => _TrafficViolationManagementQueryPageState();
}

class _TrafficViolationManagementQueryPageState extends State<TrafficViolationManagementQueryPage> {
  // 假设的违法行为记录列表
  late List<ViolationRecord> _violationRecords;

  // 控制器用于文本输入
  late TextEditingController _licensePlateController;

  // 控制器用于日期选择
  late TextEditingController _dateController;

  // 初始化日期选择器的当前日期
  late final DateTime _initialDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _violationRecords = [];
    _licensePlateController = TextEditingController();
    _dateController = TextEditingController(text: _initialDate.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('交通违法行为管理系统查询'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // 查询区域
            QuerySection(),
            SizedBox(height: 16),
            // 查询结果列表
            Expanded(
              child: ViolationRecordList(violationRecords: _violationRecords),
            ),
          ],
        ),
      ),
    );
  }

  // 查询区域
  Widget getQuerySection() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: _licensePlateController,
            decoration: InputDecoration(
              labelText: '请输入车牌号',
              prefixIcon: Icon(Icons.local_car),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入车牌号';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: '选择查询时间',
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: _initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              ).then((date) {
                setState(() {
                  _initialDate = date!;
                  _dateController.text = date.toString();
                  // 这里应该触发查询操作，获取新的违法行为记录
                });
              });
            },
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // 处理查询点击事件
            // 这里应该根据输入的车牌号和日期获取违法行为记录
            // 以下仅为示例，实际应用中需要从服务器获取数据
            _violationRecords = [
              ViolationRecord(
                plateNumber: _licensePlateController.text,
                violationType: '闯红灯',
                fineAmount: 200,
                violationTime: _initialDate.toString(),
              ),
            ];
          },
          child: Text('查询'),
        ),
      ],
    );
  }
}

// 违法行为记录列表
class ViolationRecordList extends StatelessWidget {
  final List<ViolationRecord> violationRecords;

  ViolationRecordList({required this.violationRecords});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: violationRecords.length,
      itemBuilder: (context, index) {
        final record = violationRecords[index];
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text('车牌号: ${record.plateNumber}'),
                Text('违法行为: ${record.violationType}'),
                Text('罚款金额: ${record.fineAmount}元'),
                Text('违法时间: ${record.violationTime}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 违法行为记录模型
class ViolationRecord {
  String plateNumber;
  String violationType;
  int fineAmount;
  String violationTime;

  ViolationRecord({
    required this.plateNumber,
    required this.violationType,
    required this.fineAmount,
    required this.violationTime,
  });
}