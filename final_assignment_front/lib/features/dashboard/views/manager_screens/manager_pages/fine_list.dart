import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';

class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListPageState();
}

class _FineListPageState extends State<FineList> {
  // Api
  late FineInformationControllerApi fineApi;

  // Future 用于加载列表
  late Future<List<FineInformation>> _finesFuture;

  @override
  void initState() {
    super.initState();
    fineApi = FineInformationControllerApi();
    _finesFuture = _fetchFines();
  }

  /// 获取罚款列表
  /// [payee], [startTime], [endTime] 三种方式
  Future<List<FineInformation>> _fetchFines({
    String? payee,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      // 若给定 payee
      if (payee != null && payee.isNotEmpty) {
        final responseObj = await fineApi.apiFinesPayeePayeeGet(payee: payee);
        if (responseObj == null) return [];
        // 可能是 List or single
        if (responseObj is List) {
          return responseObj.map((item) {
            return FineInformation.fromJson(item as Map<String, dynamic>);
          }).toList();
        } else if (responseObj is Map) {
          final mapObj = Map<String, dynamic>.from(responseObj);
          return [FineInformation.fromJson(mapObj)];
        }
        return [];
      }
      // 若给定时间范围
      else if (startTime != null && endTime != null) {
        // 调用 apiFinesTimeRangeGet
        final listObj = await fineApi.apiFinesTimeRangeGet(
          startTime: startTime.toIso8601String(),
          endTime: endTime.toIso8601String(),
        );
        if (listObj == null) return [];
        return listObj.map((item) {
          return FineInformation.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
      // 否则获取全部
      else {
        final listObj = await fineApi.apiFinesGet();
        if (listObj == null) return [];
        return listObj.map((item) {
          return FineInformation.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 删除罚款
  Future<void> _deleteFine(int fineId) async {
    try {
      await fineApi.apiFinesFineIdDelete(fineId: fineId.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除罚款信息成功')),
      );
      setState(() {
        _finesFuture = _fetchFines();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  /// 按缴款人搜索
  void _searchFinesByPayee(String payee) {
    setState(() {
      _finesFuture = _fetchFines(payee: payee);
    });
  }

  /// 按时间范围搜索
  void _searchFinesByTimeRange(DateTime start, DateTime end) {
    setState(() {
      _finesFuture = _fetchFines(startTime: start, endTime: end);
    });
  }

  /// 弹窗选择时间范围
  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _searchFinesByTimeRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('罚款信息列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _selectDateRange,
            tooltip: '按时间范围搜索',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 跳转到添加罚款页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFinePage()),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _finesFuture = _fetchFines();
                  });
                }
              });
            },
            tooltip: '添加新罚款',
          ),
        ],
      ),
      body: Column(
        children: [
          // 按缴款人搜索
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchFinesByPayee,
              decoration: const InputDecoration(
                labelText: '按缴款人搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: FutureBuilder<List<FineInformation>>(
              future: _finesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('加载罚款信息失败: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到罚款信息'));
                } else {
                  final fines = snapshot.data!;
                  return ListView.builder(
                    itemCount: fines.length,
                    itemBuilder: (context, index) {
                      final fine = fines[index];
                      final payee = fine.payee ?? '';
                      final amount = fine.fineAmount ?? 0;
                      final time = fine.fineTime ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('罚款金额: $amount 元'),
                          subtitle: Text('缴款人: $payee\n罚款时间: $time'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              final fid = fine.fineId;
                              if (fid != null) {
                                _deleteFine(fid);
                              }
                            },
                            tooltip: '删除此罚款记录',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FineDetailPage(fine: fine),
                              ),
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
        ],
      ),
    );
  }
}

class AddFinePage extends StatelessWidget {
  const AddFinePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 此页面用于添加新罚款信息，可参考 FineInformationPage 中的 _buildFineInfoForm
    return Scaffold(
      appBar: AppBar(title: const Text('添加新罚款')),
      body: const Center(
        child: Text('尚未实现添加罚款逻辑'),
      ),
    );
  }
}

class FineDetailPage extends StatelessWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  Widget build(BuildContext context) {
    final amount = fine.fineAmount ?? 0;
    final payee = fine.payee ?? '';
    final time = fine.fineTime ?? '';
    final receipt = fine.receiptNumber ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('罚款详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('罚款金额: $amount 元',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('缴款人: $payee', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('罚款时间: $time', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('收据号: $receipt', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
