import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final ProgressControllerApi progressApi = ProgressControllerApi();
  late List<Future<List<ProgressItem>>> _progressFutures;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('userName');
      if (jwtToken == null || username == null) {
        throw Exception('未登录或未找到用户信息');
      }

      final progressItems =
          await progressApi.apiProgressUsernameGet(username: username);
      _progressFutures = [
        Future.value(
            progressItems.where((item) => item.status == 'Pending').toList()),
        Future.value(progressItems
            .where((item) => item.status == 'Processing')
            .toList()),
        Future.value(
            progressItems.where((item) => item.status == 'Completed').toList()),
        Future.value(
            progressItems.where((item) => item.status == 'Archived').toList()),
      ];
    } catch (e) {
      _progressFutures = [
        Future.value([]),
        Future.value([]),
        Future.value([]),
        Future.value([]),
      ];
      _showErrorSnackBar('加载进度失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitProgress(ProgressItem newItem) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未找到JWT令牌');
      }

      final response = await progressApi.apiProgressPost(progressItem: newItem);
      if (response.status == 'Pending') {
        _showSuccessSnackBar('进度提交成功，等待管理员审批');
        _loadProgress();
      } else {
        throw Exception('提交失败: 状态异常');
      }
    } catch (e) {
      _showErrorSnackBar('提交进度失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: controller.currentBodyTheme.value.colorScheme.primary,
        // Dynamic color
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: controller.currentBodyTheme.value.colorScheme.error,
        // Dynamic color
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Get.toNamed(AppPages.progressDetailPage, arguments: item);
  }

  void _showSubmitProgressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        // Apply theme to dialog
        data: themeData,
        child: AlertDialog(
          backgroundColor: isLight
              ? themeData.colorScheme.surfaceContainer
              : themeData.colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            '提交新进度',
            style: themeData.textTheme.titleLarge?.copyWith(
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.95),
              fontWeight: FontWeight.bold,
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
                      color: isLight
                          ? themeData.colorScheme.onSurfaceVariant
                          : themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.85),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? themeData.colorScheme.surfaceContainerLowest
                        : themeData.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 2.0),
                    ),
                  ),
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: detailsController,
                  decoration: InputDecoration(
                    labelText: '详情',
                    labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurfaceVariant
                          : themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.85),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? themeData.colorScheme.surfaceContainerLowest
                        : themeData.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 2.0),
                    ),
                  ),
                  maxLines: 3,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  foregroundColor: themeData.colorScheme.onSurface),
              child: Text(
                '取消',
                style: themeData.textTheme.labelMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final details = detailsController.text.trim();
                if (title.isEmpty) {
                  _showErrorSnackBar('请填写进度标题');
                  return;
                }
                final newItem = ProgressItem(
                  id: 0,
                  title: title,
                  status: 'Pending',
                  submitTime: DateTime.now(),
                  details: details.isEmpty ? null : details,
                  username: '',
                );
                _submitProgress(newItem);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
              child: Text(
                '提交',
                style: themeData.textTheme.labelMedium?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Wrap with Obx for reactive theme updates
      final isLight = controller.currentTheme.value == 'Light';
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        // Apply theme dynamically
        data: themeData,
        child: Scaffold(
          backgroundColor: isLight
              ? themeData.colorScheme.surface.withOpacity(0.95)
              : themeData.colorScheme.surface.withOpacity(0.85),
          appBar: AppBar(
            title: Text(
              '进度消息',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: isLight
                    ? themeData.colorScheme.onSurface
                    : themeData.colorScheme.onSurface.withOpacity(0.95),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: isLight
                ? themeData.colorScheme.primaryContainer.withOpacity(0.9)
                : themeData.colorScheme.primaryContainer.withOpacity(0.7),
            foregroundColor: isLight
                ? themeData.colorScheme.onPrimaryContainer
                : themeData.colorScheme.onPrimaryContainer.withOpacity(0.95),
            elevation: 2,
            bottom: TabBar(
              controller: _tabController,
              labelColor: themeData.colorScheme.primary,
              unselectedLabelColor:
                  themeData.colorScheme.onSurfaceVariant.withOpacity(0.7),
              indicatorColor: themeData.colorScheme.primary,
              labelStyle: themeData.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: themeData.textTheme.labelMedium,
              tabs: const [
                Tab(text: '受理中'),
                Tab(text: '处理中'),
                Tab(text: '已完成'),
                Tab(text: '已归档'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: isLight
                      ? themeData.colorScheme.onPrimaryContainer
                      : themeData.colorScheme.onPrimaryContainer
                          .withOpacity(0.95),
                ),
                onPressed: _showSubmitProgressDialog,
                tooltip: '提交新进度',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          themeData.colorScheme.primary),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProgressList(
                          context, 'Pending', _progressFutures[0]),
                      _buildProgressList(
                          context, 'Processing', _progressFutures[1]),
                      _buildProgressList(
                          context, 'Completed', _progressFutures[2]),
                      _buildProgressList(
                          context, 'Archived', _progressFutures[3]),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildProgressList(
      BuildContext context, String status, Future<List<ProgressItem>> future) {
    final isLight = controller.currentTheme.value == 'Light';
    final themeData = controller.currentBodyTheme.value;

    return FutureBuilder<List<ProgressItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(themeData.colorScheme.primary),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error}',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.error,
                fontSize: 18,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              '暂无记录',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: isLight
                    ? themeData.colorScheme.onSurface
                    : themeData.colorScheme.onSurface.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
          );
        } else {
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: isLight
                    ? themeData.colorScheme.surfaceContainerLow
                    : themeData.colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status),
                    child: Text(
                      item.title.isNotEmpty ? item.title[0] : '?',
                      style: themeData.textTheme.labelLarge?.copyWith(
                        color: themeData.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: themeData.textTheme.bodyLarge?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurface.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '提交时间: ${item.submitTime ?? '未知'}',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurfaceVariant
                          : themeData.colorScheme.onSurfaceVariant
                              .withOpacity(0.85),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isLight
                        ? themeData.colorScheme.onSurfaceVariant
                        : themeData.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                  ),
                  onTap: () => _goToDetailPage(item),
                ),
              );
            },
          );
        }
      },
    );
  }

  Color _getStatusColor(String? status) {
    final themeData = controller.currentBodyTheme.value;
    switch (status) {
      case 'Pending':
        return themeData.colorScheme.secondary; // Orange-like
      case 'Processing':
        return themeData.colorScheme.primary; // Blue-like
      case 'Completed':
        return themeData.colorScheme.tertiary; // Green-like
      case 'Archived':
        return themeData.colorScheme.outline; // Grey-like
      default:
        return themeData.colorScheme.outlineVariant;
    }
  }
}
