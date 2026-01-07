// ignore_for_file: use_build_context_synchronously
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProgressDetailPage extends StatefulWidget {
  final ProgressItem item;

  const ProgressDetailPage({super.key, required this.item});

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  final ProgressController progressController = Get.find<ProgressController>();
  final UserDashboardController? dashboardController =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData =
          dashboardController?.currentBodyTheme.value ?? ThemeData.light();
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '进度详情',
            style: themeData.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
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
              _buildDetailRow(
                  '进度ID', widget.item.id?.toString() ?? '未知', themeData),
              _buildDetailRow('标题', widget.item.title, themeData),
              _buildDetailRow(
                  '状态', _translateStatus(widget.item.status), themeData),
              _buildDetailRow(
                '提交时间',
                DateFormat('yyyy-MM-dd HH:mm:ss')
                    .format(widget.item.submitTime),
                themeData,
              ),
              _buildDetailRow('提交用户', widget.item.username, themeData),
              _buildDetailRow('详情', widget.item.details ?? '无详情', themeData),
              _buildDetailRow(
                '关联业务',
                progressController.getBusinessContext(widget.item),
                themeData,
              ),
              if (progressController.isAdmin) ...[
                const SizedBox(height: 20),
                _buildActionButtons(themeData),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String? value, ThemeData themeData) {
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
              value ?? '未知',
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
          onPressed: () => _updateStatus('Processing', themeData),
          icon: const Icon(Icons.play_arrow),
          label: const Text('处理中'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _updateStatus('Completed', themeData),
          icon: const Icon(Icons.check),
          label: const Text('完成'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showDeleteConfirmationDialog(themeData),
          icon: const Icon(Icons.delete),
          label: const Text('删除'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.error,
            foregroundColor: themeData.colorScheme.onError,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String newStatus, ThemeData themeData) async {
    if (widget.item.id == null) {
      _showSnackBar('无法更新：进度ID为空', isError: true, themeData: themeData);
      return;
    }
    try {
      await progressController.updateProgressStatus(widget.item.id!, newStatus);
      if (mounted) {
        _showSnackBar('状态更新成功', themeData: themeData);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('更新状态失败: $e', isError: true, themeData: themeData);
      }
    }
  }

  void _showDeleteConfirmationDialog(ThemeData themeData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '确认删除',
          style: themeData.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        content: Text(
          '您确定要删除此进度记录吗？此操作不可撤销。',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: themeData.textTheme.labelLarge?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (widget.item.id == null) {
                _showSnackBar('无法删除：进度ID为空',
                    isError: true, themeData: themeData);
                Navigator.pop(ctx);
                return;
              }
              try {
                await progressController.deleteProgress(widget.item.id!);
                if (mounted) {
                  _showSnackBar('删除成功', themeData: themeData);
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('删除失败: $e',
                      isError: true, themeData: themeData);
                }
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.error,
              foregroundColor: themeData.colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message,
      {bool isError = false, required ThemeData themeData}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'Pending':
        return '待处理';
      case 'Processing':
        return '处理中';
      case 'Completed':
        return '已完成';
      case 'Archived':
        return '已归档';
      default:
        return '未知';
    }
  }
}
