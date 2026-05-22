// ignore_for_file: use_build_context_synchronously

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_message_page.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnlineProcessingProgress extends StatelessWidget {
  const OnlineProcessingProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<UserDashboardController>();

    ProgressBinding.registerDependencies();
    final progressController = Get.find<ProgressController>();

    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      final progressError = progressController.errorMessage.value;
      final showForbiddenAsEmpty = _isForbiddenProgressError(progressError);

      return DashboardPageTemplate(
        theme: themeData,
        title: '进度消息',
        pageType: DashboardPageType.custom,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: ProgressMessagePageBody(
          title: '进度消息',
          subtitle: '查看申诉、缴费和业务办理后的处理进展。',
          roleLabel: '驾驶员端',
          items: progressController.filteredItems.toList(growable: false),
          totalCount: progressController.progressItems.length,
          statusCategories:
              progressController.statusCategories.toList(growable: false),
          selectedStatus: progressController.selectedStatus.value,
          selectedStartDate: progressController.selectedStartDate.value,
          selectedEndDate: progressController.selectedEndDate.value,
          isLoading: progressController.isLoading.value,
          errorMessage: showForbiddenAsEmpty ? '' : progressError,
          hasAccess: true,
          emptyMessage: showForbiddenAsEmpty
              ? '暂无申诉办理进度。提交申诉或办理业务后，处理进展会显示在这里。'
              : '暂无进度消息',
          onRefresh: progressController.fetchProgress,
          onRetry: progressController.fetchProgress,
          onOpen: (item) => _openProgressDetail(item, progressController),
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

  bool _isForbiddenProgressError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('forbidden') ||
        normalized.contains('403') ||
        message.contains('权限不足') ||
        message.contains('无权限');
  }
}
