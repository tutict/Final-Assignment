import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  final ProgressController progressController = Get.find<ProgressController>();

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
                        color: themeData.colorScheme.primary, width: 2),
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
                        color: themeData.colorScheme.primary, width: 2),
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
              await progressController.submitProgress(
                  titleController.text, detailsController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: themeData.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
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
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          elevation: 2,
          bottom: TabBar(
            controller: _tabController,
            labelStyle: themeData.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.primary,
            ),
            unselectedLabelStyle: themeData.textTheme.labelLarge?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
            labelColor: themeData.colorScheme.primary,
            unselectedLabelColor: themeData.colorScheme.onSurfaceVariant,
            indicatorColor: themeData.colorScheme.primary,
            indicatorWeight: 3,
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
              color: themeData.colorScheme.onPrimaryContainer,
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
                          fontWeight: FontWeight.w500,
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
              style: themeData.textTheme.titleMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : ListView.builder(
            itemCount: progressController.filteredItems.length,
            itemBuilder: (context, index) {
              final item = progressController.filteredItems[index];
              return Card(
                elevation: 3,
                color: themeData.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status, themeData),
                    radius: 24,
                    child: Text(
                      item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                      style: themeData.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '提交时间: ${item.submitTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(item.submitTime!) : '未知'}',
                        style: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        progressController.getBusinessContext(item),
                        style: themeData.textTheme.bodySmall?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: themeData.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
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
