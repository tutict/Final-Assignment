import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          elevation: 2,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : !progressController.isAdmin.value
                      ? Center(
                          child: Text(
                            '权限不足：仅管理员可访问',
                            style: themeData.textTheme.titleMedium?.copyWith(
                              color: themeData.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : progressController.progressItems.isEmpty
                          ? Center(
                              child: Text(
                                '暂无进度记录',
                                style:
                                    themeData.textTheme.titleMedium?.copyWith(
                                  color: themeData.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
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
                                  elevation: 3,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(
                                          item.status, themeData),
                                      radius: 24,
                                      child: Text(
                                        item.title.isNotEmpty
                                            ? item.title[0].toUpperCase()
                                            : '?',
                                        style: themeData.textTheme.titleMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '状态: ${item.status}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: _getStatusColor(
                                                item.status, themeData),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '提交时间: ${item.submitTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(item.submitTime!) : '未知'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          progressController
                                              .getBusinessContext(item),
                                          style: themeData.textTheme.bodySmall
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                      ),
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
                                          _showDeleteConfirmationDialog(
                                              context,
                                              item.id!,
                                              progressController,
                                              themeData);
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
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            '查看/编辑',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            '删除',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color:
                                                  themeData.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'update_pending',
                                          child: Text(
                                            '设为待处理',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'update_processing',
                                          child: Text(
                                            '设为处理中',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'update_completed',
                                          child: Text(
                                            '设为已完成',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'update_archived',
                                          child: Text(
                                            '设为已归档',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
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

  void _showDeleteConfirmationDialog(BuildContext context, int progressId,
      ProgressController controller, ThemeData themeData) {
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
              await controller.deleteProgress(progressId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.error,
              foregroundColor: themeData.colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: themeData.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
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
