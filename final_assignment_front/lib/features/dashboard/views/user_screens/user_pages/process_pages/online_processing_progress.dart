import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
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
  final RoleManagementControllerApi roleApi = RoleManagementControllerApi();
  late List<Future<List<ProgressItem>>> _progressFutures;
  bool _isLoading = false;
  bool _isAdmin = false; // 确保是普通用户（非管理员）

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkUserRole(); // 检查用户角色并加载进度
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      _showErrorSnackBar('请先登录以访问此页面');
      return;
    }

    try {
      final role = await roleApi.getCurrentUserRole();
      setState(() {
        _isAdmin = role == 'ADMIN';
        if (!_isAdmin) {
          // 仅普通用户（USER）加载进度
          _loadProgress();
        } else {
          _isLoading = false; // 管理员不应访问此页面，直接关闭加载
        }
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      _showErrorSnackBar('角色验证失败: $e');
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('userName'); // 假设存储了用户名
      if (jwtToken == null || username == null) {
        throw Exception('No JWT token or username found');
      }

      final progressItems = await progressApi.apiProgressUsernameGet(
          username: username); // 使用新 API 方法
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
        throw Exception('No JWT token found');
      }

      final response = await progressApi.apiProgressPost(
          progressItem: newItem); // 使用新 API 方法

      if (response.status == 'Pending') {
        _showSuccessSnackBar('进度提交成功，等待管理员审批');
        _loadProgress(); // 刷新列表
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Get.toNamed(AppPages.progressDetailPage, arguments: item);
  }

  void _showSubmitProgressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提交新进度'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '进度标题'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: '详情'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
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
                // 后端自动生成
                title: title,
                status: 'Pending',
                submitTime: DateTime.now().toIso8601String(),
                details: details.isEmpty ? null : details,
                username: '', // 后端会从 JWT 解析
              );
              _submitProgress(newItem);
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
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (_isAdmin) {
      // 管理员不应访问此页面，提示并返回
      return Scaffold(
        body: Center(
          child: Text(
            '权限不足：此页面仅限普通用户访问',
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('进度消息'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: currentTheme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: currentTheme.colorScheme.primary,
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
              ), // 普通用户始终可以提交新进度
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
      ),
    );
  }

  Widget _buildProgressList(
      BuildContext context, String status, Future<List<ProgressItem>> future) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return FutureBuilder<List<ProgressItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: currentTheme.colorScheme.primary));
        } else if (snapshot.hasError) {
          return Center(
              child: Text('加载失败: ${snapshot.error}',
                  style: TextStyle(color: currentTheme.colorScheme.error)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('暂无记录',
                  style: TextStyle(color: currentTheme.colorScheme.onSurface)));
        } else {
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: isLight ? Colors.white : Colors.grey[800],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status),
                    child: Text(
                      item.title[0],
                      style: TextStyle(
                        color: currentTheme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(color: currentTheme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '提交时间: ${item.submitTime}',
                    style: TextStyle(
                        color: currentTheme.colorScheme.onSurface
                            .withOpacity(0.7)),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () => _goToDetailPage(item),
                ),
              );
            },
          );
        }
      },
    );
  }

  Color _getStatusColor(String status) {
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
