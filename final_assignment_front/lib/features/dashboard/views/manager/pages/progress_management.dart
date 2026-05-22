import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_message_page.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/shared/dialogs/app_dialog.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProgressManagementPage extends StatelessWidget {
  const ProgressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<ManagerDashboardController>();

    ProgressBinding.registerDependencies();
    final progressController = Get.find<ProgressController>();

    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      final isAdmin = progressController.isAdmin;

      return DashboardPageTemplate(
        theme: themeData,
        title: '进度管理',
        pageType: DashboardPageType.manager,
        onRefresh: progressController.fetchProgress,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: ProgressMessagePageBody(
          title: '进度管理',
          subtitle: '集中查看用户提交进度、关联业务和处理状态。',
          roleLabel: '管理员端',
          items: progressController.filteredItems.toList(growable: false),
          totalCount: progressController.progressItems.length,
          statusCategories:
              progressController.statusCategories.toList(growable: false),
          selectedStatus: progressController.selectedStatus.value,
          selectedStartDate: progressController.selectedStartDate.value,
          selectedEndDate: progressController.selectedEndDate.value,
          isLoading: progressController.isLoading.value,
          errorMessage: progressController.errorMessage.value,
          hasAccess: isAdmin,
          permissionHint: '权限不足：仅管理员可访问进度管理',
          emptyMessage: '暂无进度记录',
          onRetry: progressController.fetchProgress,
          onCreate: isAdmin
              ? () => _showCreateProgressDialog(
                    context,
                    progressController,
                    themeData,
                  )
              : null,
          onOpen: (item) => _openProgressDetail(item, progressController),
          onDelete: isAdmin
              ? (item) => _showDeleteConfirmationDialog(
                    context,
                    progressController,
                    item,
                  )
              : null,
          onStatusChange: isAdmin
              ? (item, status) => _updateProgressStatus(
                    context,
                    progressController,
                    item,
                    status,
                    themeData,
                  )
              : null,
          businessContextBuilder: progressController.getBusinessContext,
          onStatusSelected: progressController.filterByStatus,
          onDateRangePressed: () =>
              _showDateRangePicker(progressController, themeData),
          onClearFilters: () async {
            progressController.clearFilters();
            await progressController.fetchProgress();
          },
        ),
      );
    });
  }

  void _openProgressDetail(
    ProgressItem item,
    ProgressController progressController,
  ) {
    NavigationHelper.toNamed(Routes.progressDetailPage, arguments: item)
        .then((result) {
      if (result == true) {
        progressController.fetchProgress();
      }
    });
  }

  void _showDateRangePicker(
    ProgressController controller,
    ThemeData themeData,
  ) async {
    final initialStartDate = controller.selectedStartDate.value ??
        DateTime.now().subtract(const Duration(days: 7));
    final initialEndDate = controller.selectedEndDate.value ?? DateTime.now();

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

  void _showCreateProgressDialog(
    BuildContext context,
    ProgressController controller,
    ThemeData themeData,
  ) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    AppealRecordModel? selectedAppeal;

    ui.AppDialog.showCustomDialog<void>(
      context: context,
      theme: themeData,
      title: '创建进度',
      content: StatefulBuilder(
        builder: (ctx, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    prefixIcon: Icon(Icons.subject_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: '详情（可选）',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Obx(
                  () => DropdownButtonFormField<AppealRecordModel>(
                    decoration: const InputDecoration(
                      labelText: '关联申诉（可选）',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    initialValue: selectedAppeal,
                    isExpanded: true,
                    items: controller.appeals.map((appeal) {
                      return DropdownMenuItem(
                        value: appeal,
                        child: Text(
                          '申诉：${appeal.appellantName}（ID：${appeal.appealId}）',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedAppeal = value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();
            final details = detailsController.text.trim();
            if (title.isEmpty) {
              ui.AppSnackbar.showError(
                context,
                message: '标题不能为空',
                theme: themeData,
              );
              return;
            }

            controller.submitProgress(
              title,
              details.isEmpty ? null : details,
              appealId: selectedAppeal?.appealId,
            );
            Navigator.of(context).pop();
          },
          child: const Text('提交'),
        ),
      ],
    ).whenComplete(() {
      titleController.dispose();
      detailsController.dispose();
    });
  }

  Future<void> _updateProgressStatus(
    BuildContext context,
    ProgressController controller,
    ProgressItem item,
    String status,
    ThemeData themeData,
  ) async {
    if (item.id == null) {
      ui.AppSnackbar.showError(
        context,
        message: '无法更新：进度ID为空',
        theme: themeData,
      );
      return;
    }
    await controller.updateProgressStatus(item.id!, status);
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    ProgressController controller,
    ProgressItem item,
  ) async {
    if (item.id == null) {
      ui.AppSnackbar.showError(
        context,
        message: '无法删除：进度ID为空',
        theme: Theme.of(context),
      );
      return;
    }

    final confirmed = await AppDialog.showConfirmDelete(
      context,
      itemName: '该进度记录',
      extraWarning: '此操作不可撤销。',
    );
    if (confirmed == true) {
      await controller.deleteProgress(item.id!);
    }
  }
}
