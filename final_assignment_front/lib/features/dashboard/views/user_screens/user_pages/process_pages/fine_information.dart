import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';

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

  /// 获取全部罚款信息
  Future<List<FineInformation>> _fetchAllFines() async {
    try {
      final listObj = await fineApi.apiFinesGet();
      if (listObj == null) return [];
      // listObj 是 List<Object> -> 转换为 List<FineInformation>
      return listObj.map((item) {
        return FineInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 提交罚款信息
  Future<void> _submitFineInfo() async {
    try {
      // 构造 FineInformation 对象
      final fineInfo = FineInformation();
      fineInfo.offenseId = 0; // 示例，如需要 offenseId
      fineInfo.fineAmount = double.tryParse(_fineAmountController.text) ?? 0.0;
      fineInfo.payee = _payeeController.text.trim();
      fineInfo.accountNumber = _accountNumberController.text.trim();
      fineInfo.bank = _bankController.text.trim();
      fineInfo.receiptNumber = _receiptNumberController.text.trim();
      fineInfo.remarks = _remarksController.text.trim();
      fineInfo.fineTime = _dateController.text.trim();

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
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
            // 搜索或时间查询区域 (可按需添加)
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
                          title: Text('罚款金额: $amount'),
                          subtitle: Text('缴款人: $payee / 时间: $date'),
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

  Widget _buildFineInfoForm() {
    return Column(
      children: [
        TextField(
          controller: _plateNumberController,
          decoration: const InputDecoration(
            labelText: '车牌号',
            prefixIcon: Icon(Icons.local_bar),
          ),
        ),
        TextField(
          controller: _fineAmountController,
          decoration: const InputDecoration(
            labelText: '罚款金额',
            prefixIcon: Icon(Icons.money),
          ),
          keyboardType: TextInputType.number,
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
            labelText: '账户号码',
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        TextField(
          controller: _bankController,
          decoration: const InputDecoration(
            labelText: '银行',
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        TextField(
          controller: _receiptNumberController,
          decoration: const InputDecoration(
            labelText: '收据号码',
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
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              _dateController.text = pickedDate.toIso8601String();
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitFineInfo,
          child: const Text('提交罚款信息'),
        ),
      ],
    );
  }
}
