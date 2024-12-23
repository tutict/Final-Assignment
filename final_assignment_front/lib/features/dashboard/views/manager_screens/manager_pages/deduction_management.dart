// 引入你提供的 API 与 model
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:flutter/material.dart';

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  // 用于发起HTTP请求
  late DeductionInformationControllerApi deductionApi;

  // Future 用于加载“扣分信息”列表
  late Future<List<DeductionInformation>> _deductionsFuture;

  @override
  void initState() {
    super.initState();
    deductionApi = DeductionInformationControllerApi();
    _deductionsFuture = _fetchDeductions();
  }

  /// 获取所有扣分信息
  Future<List<DeductionInformation>> _fetchDeductions() async {
    try {
      // 调用后端接口
      final listObj = await deductionApi.apiDeductionsGet();
      if (listObj == null) return [];
      // listObj 是 List<Object>，转换为 List<DeductionInformation>
      return listObj.map((item) {
        return DeductionInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // 可以在此处处理或者抛出异常
      rethrow;
    }
  }

  /// 删除指定扣分信息
  Future<void> _deleteDeduction(int deductionId) async {
    try {
      await deductionApi.apiDeductionsDeductionIdDelete(
        deductionId: deductionId.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除扣分信息成功')),
      );
      // 重新加载列表
      setState(() {
        _deductionsFuture = _fetchDeductions();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  /// 这里示例一个跳转到“添加扣分”页面的按钮回调
  void _goToAddDeductionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDeductionPage()),
    ).then((value) {
      // 如果在添加页面成功添加，则刷新列表
      if (value == true) {
        setState(() {
          _deductionsFuture = _fetchDeductions();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扣分信息管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToAddDeductionPage,
            tooltip: '添加新的扣分记录',
          ),
        ],
      ),
      body: FutureBuilder<List<DeductionInformation>>(
        future: _deductionsFuture,
        builder: (context, snapshot) {
          // 正在加载
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 出错
          else if (snapshot.hasError) {
            return Center(child: Text('加载扣分信息失败: ${snapshot.error}'));
          }
          // 空数据
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无扣分记录'));
          }
          // 有数据
          else {
            final deductions = snapshot.data!;
            return ListView.builder(
              itemCount: deductions.length,
              itemBuilder: (context, index) {
                final deduction = deductions[index];
                final points = deduction.deductedPoints ?? 0;
                final time = deduction.deductionTime ?? '未知';
                final handler = deduction.handler ?? '未记录';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    title: Text('扣分: $points 分'),
                    subtitle: Text('时间: $time\n处理人: $handler'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: '删除',
                      onPressed: () {
                        final did = deduction.deductionId;
                        if (did != null) {
                          _deleteDeduction(did);
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeductionDetailPage(
                                deduction: deduction,
                              ),
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
    );
  }
}

/// 示例：添加扣分页面 (可参照 FineInformationPage 的表单写法)
class AddDeductionPage extends StatelessWidget {
  const AddDeductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 实现添加扣分的表单
    return Scaffold(
      appBar: AppBar(title: const Text('添加扣分信息')),
      body: const Center(
          child: Text('此处实现表单逻辑, 提交后调用 apiDeductionsPost(...)')),
    );
  }
}

/// 示例：扣分详情页
class DeductionDetailPage extends StatelessWidget {
  final DeductionInformation deduction;

  const DeductionDetailPage({super.key, required this.deduction});

  @override
  Widget build(BuildContext context) {
    final points = deduction.deductedPoints ?? 0;
    final time = deduction.deductionTime ?? '未知';
    final handler = deduction.handler ?? '未记录';
    final remarks = deduction.remarks ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('扣分详情')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('扣分 ID: ${deduction.deductionId}'),
            const SizedBox(height: 8.0),
            Text('扣分分数: $points'),
            const SizedBox(height: 8.0),
            Text('扣分时间: $time'),
            const SizedBox(height: 8.0),
            Text('处理人: $handler'),
            const SizedBox(height: 8.0),
            Text('备注: $remarks'),
          ],
        ),
      ),
    );
  }
}
