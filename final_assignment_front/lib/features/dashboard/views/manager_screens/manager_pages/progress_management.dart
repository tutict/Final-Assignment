import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 添加日期格式化依赖

class ProgressManagementPage extends StatelessWidget {
  const ProgressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController =
        Get.find<DashboardController>();
    final ProgressController progressController =
        Get.find<ProgressController>();

    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '进度管理',
            style: themeData.textTheme.headlineSmall?.copyWith(
              color: themeData.colorScheme.onPrimary,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: progressController.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(themeData.colorScheme.primary),
                  ),
                )
              : progressController.errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        progressController.errorMessage.value,
                        style: themeData.textTheme.bodyLarge?.copyWith(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                    )
                  : !progressController.isAdmin.value
                      ? Center(
                          child: Text(
                            '权限不足：仅管理员可访问',
                            style: themeData.textTheme.bodyLarge?.copyWith(
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        )
                      : progressController.progressItems.isEmpty
                          ? Center(
                              child: Text(
                                '暂无进度记录',
                                style: themeData.textTheme.bodyLarge?.copyWith(
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  progressController.progressItems.length,
                              itemBuilder: (context, index) {
                                final item =
                                    progressController.progressItems[index];
                                return Card(
                                  elevation: 2,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(
                                          item.status, themeData),
                                      child: Text(
                                        item.title.isNotEmpty
                                            ? item.title[0]
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: themeData.textTheme.bodyLarge,
                                    ),
                                    subtitle: Text(
                                      '状态: ${item.status}\n'
                                      '提交时间: ${item.submitTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(item.submitTime!) : '未知'}\n'
                                      '${progressController.getBusinessContext(item)}',
                                      style: themeData.textTheme.bodyMedium,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Get.toNamed(
                                                  AppPages.progressDetailPage,
                                                  arguments: item)
                                              ?.then((result) {
                                            if (result == true) {
                                              progressController
                                                  .fetchProgress();
                                            }
                                          });
                                        } else if (value == 'delete') {
                                          _showDeleteConfirmationDialog(context,
                                              item.id!, progressController);
                                        } else if (value
                                            .startsWith('update_')) {
                                          progressController
                                              .updateProgressStatus(
                                            item.id!,
                                            value
                                                .split('_')[1]
                                                .capitalizeFirst!,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('查看/编辑')),
                                        const PopupMenuItem(
                                            value: 'delete', child: Text('删除')),
                                        const PopupMenuItem(
                                            value: 'update_pending',
                                            child: Text('设为待处理')),
                                        const PopupMenuItem(
                                            value: 'update_processing',
                                            child: Text('设为处理中')),
                                        const PopupMenuItem(
                                            value: 'update_completed',
                                            child: Text('设为已完成')),
                                        const PopupMenuItem(
                                            value: 'update_archived',
                                            child: Text('设为已归档')),
                                      ],
                                    ),
                                    onTap: () => Get.toNamed(
                                            AppPages.progressDetailPage,
                                            arguments: item)
                                        ?.then((result) {
                                      if (result == true) {
                                        progressController.fetchProgress();
                                      }
                                    }),
                                  ),
                                );
                              },
                            ),
        ),
      );
    });
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, int progressId, ProgressController controller) {
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
              await controller.deleteProgress(progressId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status, ThemeData themeData) {
    switch (status) {
      case 'Pending':
        return themeData.colorScheme.secondary;
      case 'Processing':
        return themeData.colorScheme.primary;
      case 'Completed':
        return themeData.colorScheme.tertiary;
      case 'Archived':
        return themeData.colorScheme.outline;
      default:
        return themeData.colorScheme.outlineVariant;
    }
  }
}
