import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart'; // 主题支持
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 用于格式化日期

class ProgressDetailPage extends StatefulWidget {
  final ProgressItem item;

  const ProgressDetailPage({super.key, required this.item});

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  final ProgressController progressController = Get.find<ProgressController>(); // 注入控制器
  final UserDashboardController? dashboardController =
  Get.isRegistered<UserDashboardController>()
      ? Get.find<UserDashboardController>()
      : null;

  @override
  Widget build(BuildContext context) {
    final themeData = dashboardController?.currentBodyTheme.value ?? ThemeData.light();

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '进度详情',
          style: themeData.textTheme.titleLarge?.copyWith(
            color: themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailRow('进度ID', widget.item.id?.toString() ?? '未知', themeData),
            _buildDetailRow('标题', widget.item.title, themeData),
            _buildDetailRow('状态', widget.item.status, themeData),
            _buildDetailRow(
              '提交时间',
              DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.item.submitTime),
              themeData,
            ),
            _buildDetailRow('提交用户', widget.item.username, themeData),
            _buildDetailRow(
              '详情',
              widget.item.details ?? '无详情',
              themeData,
            ),
            _buildDetailRow(
              '关联业务',
              progressController.getBusinessContext(widget.item),
              themeData,
            ),
            if (progressController.isAdmin.value) ...[
              const SizedBox(height: 20),
              _buildActionButtons(themeData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData themeData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _updateStatus('Processing'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('处理中'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _updateStatus('Completed'),
          icon: const Icon(Icons.check),
          label: const Text('完成'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showDeleteConfirmationDialog,
          icon: const Icon(Icons.delete),
          label: const Text('删除'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.error,
            foregroundColor: themeData.colorScheme.onError,
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    if (widget.item.id == null) return;
    try {
      await progressController.updateProgressStatus(widget.item.id!, newStatus);
      if (mounted) Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      _showSnackBar('更新状态失败: $e', isError: true);
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('您确定要删除此进度记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (widget.item.id != null) {
                await progressController.deleteProgress(widget.item.id!);
                if (mounted) Navigator.pop(context, true); // 返回并刷新列表
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}