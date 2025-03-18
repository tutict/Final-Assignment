import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 添加日期格式化依赖

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController dashboardController =
      Get.find<UserDashboardController>();
  final ProgressController progressController =
      Get.find<ProgressController>(); // 使用 find 而不是 put，避免重复注入

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        progressController.filterByStatus(
            progressController.statusCategories[_tabController.index]);
      }
    });
    // 确保初始加载时过滤正确
    progressController.filterByStatus(
        progressController.statusCategories[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSubmitProgressDialog() {
    final themeData = dashboardController.currentBodyTheme.value;
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
        title: Text('提交新进度', style: themeData.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '进度标题',
                  labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: themeData.colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: '详情',
                  labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: themeData.colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: TextStyle(color: themeData.colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () async {
              await progressController.submitProgress(
                  titleController.text, detailsController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
            ),
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '进度消息',
            style: themeData.textTheme.headlineSmall?.copyWith(
              color: themeData.colorScheme.onPrimary,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimary,
          bottom: TabBar(
            controller: _tabController,
            labelColor: themeData.colorScheme.primary,
            unselectedLabelColor: themeData.colorScheme.onSurfaceVariant,
            indicatorColor: themeData.colorScheme.primary,
            tabs: const [
              Tab(text: '受理中'),
              Tab(text: '处理中'),
              Tab(text: '已完成'),
              Tab(text: '已归档'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              color: themeData.colorScheme.onPrimary,
              onPressed: _showSubmitProgressDialog,
              tooltip: '提交新进度',
            ),
          ],
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
                  : TabBarView(
                      controller: _tabController,
                      children: progressController.statusCategories
                          .map((status) => _buildProgressList(themeData))
                          .toList(),
                    ),
        ),
      );
    });
  }

  Widget _buildProgressList(ThemeData themeData) {
    return Obx(() => progressController.filteredItems.isEmpty
        ? Center(
            child: Text(
              '暂无记录',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurface,
              ),
            ),
          )
        : ListView.builder(
            itemCount: progressController.filteredItems.length,
            itemBuilder: (context, index) {
              final item = progressController.filteredItems[index];
              return Card(
                elevation: 2,
                color: themeData.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status, themeData),
                    child: Text(
                      item.title.isNotEmpty ? item.title[0] : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: themeData.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    '提交时间: ${item.submitTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(item.submitTime!) : '未知'}\n'
                    '${progressController.getBusinessContext(item)}',
                    style: themeData.textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () =>
                      Get.toNamed(AppPages.progressDetailPage, arguments: item)
                          ?.then((result) {
                    if (result == true) progressController.fetchProgress();
                  }),
                ),
              );
            },
          ));
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
