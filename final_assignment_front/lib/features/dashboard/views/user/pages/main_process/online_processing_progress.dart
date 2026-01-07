// ignore_for_file: use_build_context_synchronously

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OnlineProcessingProgress extends StatelessWidget {
  const OnlineProcessingProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final UserDashboardController dashboardController =
        Get.find<UserDashboardController>();

// Ensure ProgressController is registered (fallback, but prefer global registration)
    ProgressController progressController;
    try {
      progressController = Get.find<ProgressController>();
    } catch (e) {
      progressController = Get.put(ProgressController());
      debugPrint('ProgressController was not found; registered locally: $e');
    }

    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: '进度消息',
        pageType: DashboardPageType.user,
        onThemeToggle: dashboardController.toggleBodyTheme,
        onRefresh: () => progressController.fetchProgress(),
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildFilterControls(context, progressController, themeData),
              const SizedBox(height: 16),
              Expanded(
                child: progressController.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                              themeData.colorScheme.primary),
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
                        : progressController.filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无进度记录',
                                  style:
                                      themeData.textTheme.titleMedium?.copyWith(
                                    color:
                                        themeData.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    progressController.filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      progressController.filteredItems[index];
                                  return Card(
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                          color:
                                              themeData.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '状态: ${_translateStatus(item.status)}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: _getStatusColor(
                                                  item.status, themeData),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '提交时间: ${DateFormat('yyyy-MM-dd HH:mm').format(item.submitTime)}',
                                            style: themeData
                                                .textTheme.bodyMedium
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
                                                  .withValues(alpha: 0.8),
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
                                          if (value == 'view') {
                                            Get.toNamed(
                                                    AppPages.progressDetailPage,
                                                    arguments: item)
                                                ?.then((result) {
                                              if (result == true) {
                                                progressController
                                                    .fetchProgress();
                                              }
                                            });
                                          } else if (value == 'edit') {
                                            _showEditProgressDialog(
                                                context,
                                                themeData,
                                                progressController,
                                                item);
                                          } else if (value == 'delete') {
                                            _showDeleteConfirmationDialog(
                                                context,
                                                themeData,
                                                progressController,
                                                item.id!);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'view',
                                            child: Text(
                                              '查看详情',
                                              style: themeData
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: themeData
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(
                                              '编辑',
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
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterControls(BuildContext context,
      ProgressController controller, ThemeData themeData) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: controller.statusCategories.isNotEmpty
                ? controller.statusCategories.first
                : null,
            decoration: InputDecoration(
              labelText: '状态筛选',
              labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeData.colorScheme.outline,
                ),
              ),
              filled: true,
              fillColor: themeData.colorScheme.surfaceContainer,
            ),
            items: controller.statusCategories.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  _translateStatus(status),
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.filterByStatus(value);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.date_range,
            color: themeData.colorScheme.primary,
          ),
          onPressed: () => _showDateRangePicker(controller, themeData),
          tooltip: '按时间范围筛选',
        ),
        IconButton(
          icon: Icon(
            Icons.clear,
            color: themeData.colorScheme.error,
          ),
          onPressed: () {
            controller.clearTimeRangeFilter();
            controller.fetchProgress();
          },
          tooltip: '清除筛选',
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () =>
              _showSubmitProgressDialog(context, themeData, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('提交新进度'),
        ),
      ],
    );
  }

  void _showDateRangePicker(
      ProgressController controller, ThemeData themeData) async {
    final initialStartDate = DateTime.now().subtract(const Duration(days: 7));
    final initialEndDate = DateTime.now();

    final pickedRange = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: themeData.copyWith(
            colorScheme: themeData.colorScheme.copyWith(
              primary: themeData.colorScheme.primary,
              onPrimary: themeData.colorScheme.onPrimary,
              surface: themeData.colorScheme.surface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      await controller.fetchProgressByTimeRange(
        pickedRange.start,
        pickedRange.end,
      );
    }
  }

  void _showSubmitProgressDialog(BuildContext context, ThemeData themeData,
      ProgressController progressController) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '提交新进度',
          style: themeData.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '进度标题',
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: '详情',
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 3,
                style: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ],
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
              if (titleController.text.isEmpty ||
                  detailsController.text.isEmpty) {
                Get.snackbar('错误', '标题和详情不能为空',
                    snackPosition: SnackPosition.TOP);
                return;
              }
              await progressController.submitProgress(
                titleController.text,
                detailsController.text,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: themeData.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  void _showEditProgressDialog(BuildContext context, ThemeData themeData,
      ProgressController progressController, ProgressItem item) {
    final titleController = TextEditingController(text: item.title);
    final detailsController = TextEditingController(text: item.details);
    String selectedStatus = item.status;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '编辑进度',
          style: themeData.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '进度标题',
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: '详情',
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 3,
                style: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: '状态',
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: progressController.statusCategories.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      _translateStatus(status),
                      style: themeData.textTheme.bodyMedium?.copyWith(
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
              ),
            ],
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
              if (titleController.text.isEmpty ||
                  detailsController.text.isEmpty) {
                Get.snackbar('错误', '标题和详情不能为空',
                    snackPosition: SnackPosition.TOP);
                return;
              }
              await progressController.updateProgress(
                item.id!,
                titleController.text,
                detailsController.text,
                selectedStatus,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: themeData.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, ThemeData themeData,
      ProgressController progressController, int id) {
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
          '确定要删除此进度记录吗？此操作不可撤销。',
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
              await progressController.deleteProgress(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.error,
              foregroundColor: themeData.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: themeData.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('删除'),
          ),
        ],
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
