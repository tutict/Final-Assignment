import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  var uuid = const Uuid();
  return uuid.v4();
}

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage> {
  // 用于与后端交互的API
  late FineInformationControllerApi fineApi;

  // 用于存储从服务器获取的罚款信息列表
  late Future<List<FineInformation>> _finesFuture;

  // 控制器：用于输入表单
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
    fineApi = FineInformationControllerApi();
    _finesFuture = _fetchAllFines();
  }

  @override
  void dispose() {
    // 释放资源
    _plateNumberController.dispose();
    _fineAmountController.dispose();
    _payeeController.dispose();
    _accountNumberController.dispose();
    _bankController.dispose();
    _receiptNumberController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<FineInformation>> _fetchAllFines() async {
    try {
      final List<FineInformation>? listObj =
          await fineApi.apiFinesFineIdGet(fineId: '');
      return listObj ?? [];
    } catch (e) {
      // 这里可以进行更详细的错误处理或日志记录
      // 例如，记录错误日志或显示错误消息
      debugPrint('Error fetching fines: $e');
      rethrow;
    }
  }

  /// 提交罚款信息
  Future<void> _submitFineInfo() async {
    try {
      // 生成幂等性键
      final String idempotencyKey = generateIdempotencyKey();

      // 构造 FineInformation 对象
      final fineInfo = FineInformation(
        fineId: null,
        // 由后端生成
        offenseId: 0,
        // 示例，如需要 offenseId，请根据实际情况修改
        fineAmount: double.tryParse(_fineAmountController.text) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bank: _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        fineTime: _dateController.text.trim(),
        idempotencyKey: idempotencyKey,
      );

      // 提交到后端
      await fineApi.apiFinesPost(fineInformation: fineInfo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('罚款信息提交成功')),
      );

      // 刷新列表
      setState(() {
        _finesFuture = _fetchAllFines();
      });

      // 清空表单
      _plateNumberController.clear();
      _fineAmountController.clear();
      _payeeController.clear();
      _accountNumberController.clear();
      _bankController.clear();
      _receiptNumberController.clear();
      _remarksController.clear();
      _dateController.clear();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
      );
    }
  }

  /// 删除罚款信息
  Future<void> _deleteFine(int? fineId) async {
    if (fineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的罚款ID')),
      );
      return;
    }

    try {
      await fineApi.apiFinesFineIdDelete(
        fineId: fineId.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('罚款信息删除成功')),
      );

      // 刷新列表
      setState(() {
        _finesFuture = _fetchAllFines();
      });
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交通违法罚款记录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // 罚款记录输入表单
            _buildFineInfoForm(),
            const SizedBox(height: 16),
            // 罚款记录列表
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
                    return const Center(
                      child: Text('暂无罚款记录'),
                    );
                  } else {
                    final fines = snapshot.data!;
                    return ListView.builder(
                      itemCount: fines.length,
                      itemBuilder: (context, index) {
                        final record = fines[index];
                        final amount = record.fineAmount ?? 0;
                        final payee = record.payee ?? '';
                        final date = record.fineTime ?? '';
                        return ListTile(
                          title: Text('罚款金额: \$${amount.toStringAsFixed(2)}'),
                          subtitle: Text('缴款人: $payee / 时间: $date'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteFine(record.fineId);
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
      ),
    );
  }

  /// 构建罚款信息输入表单
  Widget _buildFineInfoForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _plateNumberController,
            decoration: const InputDecoration(
              labelText: '车牌号',
              prefixIcon: Icon(Icons.local_car_wash),
            ),
          ),
          TextField(
            controller: _fineAmountController,
            decoration: const InputDecoration(
              labelText: '罚款金额 (\$)',
              prefixIcon: Icon(Icons.money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _payeeController,
            decoration: const InputDecoration(
              labelText: '收款人',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          TextField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: '银行账号',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
          TextField(
            controller: _bankController,
            decoration: const InputDecoration(
              labelText: '银行名称',
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
          ),
          TextField(
            controller: _receiptNumberController,
            decoration: const InputDecoration(
              labelText: '收据编号',
              prefixIcon: Icon(Icons.receipt),
            ),
          ),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: '备注',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: '罚款日期',
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode()); // 关闭键盘
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  _dateController.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                });
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitFineInfo,
            child: const Text('提交罚款信息'),
          ),
        ],
      ),
    );
  }
}
