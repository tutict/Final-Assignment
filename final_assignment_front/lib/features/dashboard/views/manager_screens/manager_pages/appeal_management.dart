import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';

class AppealManagementAdmin extends StatelessWidget {
  final AppealManagement? appeal; // Nullable parameter

  const AppealManagementAdmin({super.key, this.appeal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: appeal != null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldRow(
                        '申诉ID', appeal!.appealId?.toString() ?? '未提供'),
                    _buildFieldRow(
                        '违法记录ID', appeal!.offenseId?.toString() ?? '未提供'),
                    _buildFieldRow('上诉人姓名', appeal!.appellantName ?? '未提供'),
                    _buildFieldRow('身份证号码', appeal!.idCardNumber ?? '未提供'),
                    _buildFieldRow('联系电话', appeal!.contactNumber ?? '未提供'),
                    _buildFieldRow('上诉原因', appeal!.appealReason ?? '未提供'),
                    _buildFieldRow(
                        '上诉时间', appeal!.appealTime?.toIso8601String() ?? '未提供'),
                    _buildFieldRow('处理状态', appeal!.processStatus ?? '未提供'),
                    _buildFieldRow('处理结果', appeal!.processResult ?? '未提供'),
                    _buildFieldRow('幂等键', appeal!.idempotencyKey),
                  ],
                ),
              )
            : const Center(
                child: Text(
                  '未提供申诉数据',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
