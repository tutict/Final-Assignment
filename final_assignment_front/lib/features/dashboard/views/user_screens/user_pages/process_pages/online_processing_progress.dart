import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final ProgressController progressController = Get.put(ProgressController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      progressController.filterByStatus(
          progressController.statusCategories[_tabController.index]);
    });
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: '详情',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              progressController.submitProgress(
                  titleController.text, detailsController.text);
              Navigator.pop(ctx);
            },
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
          title: Text('进度消息', style: themeData.textTheme.headlineSmall),
          backgroundColor: themeData.colorScheme.primaryContainer,
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
                      valueColor: AlwaysStoppedAnimation(
                          themeData.colorScheme.primary)))
              : progressController.errorMessage.isNotEmpty
                  ? Center(
                      child: Text(progressController.errorMessage.value,
                          style: themeData.textTheme.bodyLarge))
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
        ? Center(child: Text('暂无记录', style: themeData.textTheme.bodyLarge))
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
                    child: Text(item.title.isNotEmpty ? item.title[0] : '?',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(item.title, style: themeData.textTheme.bodyLarge),
                  subtitle: Text('提交时间: ${item.submitTime ?? '未知'}',
                      style: themeData.textTheme.bodyMedium),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () =>
                      Get.toNamed(AppPages.progressDetailPage, arguments: item),
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
