import 'package:flutter/material.dart';

class TrafficFineRecordPage extends StatefulWidget {
  const TrafficFineRecordPage({super.key});

  @override
  _TrafficFineRecordPageState createState() => _TrafficFineRecordPageState();
}

class _TrafficFineRecordPageState extends State<TrafficFineRecordPage> {
  // 假设的罚款记录列表
  final List<FineRecord> _fineRecords = [
    FineRecord(id: 1, plateNumber: '京A0001', fineAmount: 200, date: '2024-04-01'),
    FineRecord(id: 2, plateNumber: '京A0002', fineAmount: 500, date: '2024-04-10'),
    // ... 更多罚款记录
  ];

  // 用于搜索的车牌号
  final String _searchPlateNumber = '';

  // 用于搜索的时间
  final String _searchDate = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5G 交通违法罚款记录'),
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

  FineRecord({required this.id, required this.plateNumber, required this.fineAmount, required this.date});
}