import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
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
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Get.toNamed(AppPages.progressDetailPage, arguments: item);
  }

  void _showSubmitProgressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final themeData = controller.currentBodyTheme.value;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
        title: Text(
          '提交新进度',
          style: themeData.textTheme.titleLarge?.copyWith(
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
                  labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 2.0),
                  ),
                ),
                style: TextStyle(color: themeData.colorScheme.onSurface),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: '详情',
                  labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 2.0),
                  ),
                ),
                maxLines: 3,
                style: TextStyle(color: themeData.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: themeData.textTheme.labelMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
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
                submitTime: DateTime.now().toIso8601String(),
                details: details.isEmpty ? null : details,
                username: '',
              );
              _submitProgress(newItem);
              Navigator.pop(ctx);
            },
            style: themeData.elevatedButtonTheme.style?.copyWith(
              backgroundColor:
                  WidgetStateProperty.all(themeData.colorScheme.primary),
              foregroundColor:
                  WidgetStateProperty.all(themeData.colorScheme.onPrimary),
            ),
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '进度消息',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
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
            icon: Icon(Icons.add,
                color: themeData.colorScheme.onPrimaryContainer),
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
                  _buildProgressList(context, 'Pending', _progressFutures[0]),
                  _buildProgressList(
                      context, 'Processing', _progressFutures[1]),
                  _buildProgressList(context, 'Completed', _progressFutures[2]),
                  _buildProgressList(context, 'Archived', _progressFutures[3]),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressList(
      BuildContext context, String status, Future<List<ProgressItem>> future) {
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
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              '暂无记录',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurface,
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
                color: themeData.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status),
                    child: Text(
                      item.title[0],
                      style: TextStyle(
                        color: themeData.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: themeData.textTheme.bodyLarge?.copyWith(
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '提交时间: ${item.submitTime}',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: themeData.colorScheme.onSurfaceVariant,
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
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
