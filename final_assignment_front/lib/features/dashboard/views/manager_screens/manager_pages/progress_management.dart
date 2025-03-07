import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/process_pages/online_processing_progress.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressManagementPage extends StatefulWidget {
  const ProgressManagementPage({super.key});

  @override
  State<ProgressManagementPage> createState() => _ProgressManagementPageState();
}

class _ProgressManagementPageState extends State<ProgressManagementPage> {
  final DashboardController controller = Get.find<DashboardController>();
  final ProgressControllerApi progressApi = ProgressControllerApi();
  List<ProgressItem> _progressItems = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('userName');
      if (jwtToken == null || username == null) {
        throw Exception('未登录或未找到用户信息');
      }

      await progressApi.initializeWithJwt();
      final userRole = prefs.getString('userRole');
      setState(() {
        _isAdmin = userRole == 'ADMIN';
        if (_isAdmin) {
          _fetchAllProgress();
        } else {
          _errorMessage = '权限不足：仅管理员可访问此页面';
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '验证失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await progressApi.initializeWithJwt();
      final progressItems = await progressApi.apiProgressGet();
      setState(() {
        _progressItems = progressItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载进度失败: $e';
      });
    }
  }

  Future<void> _updateProgressStatus(int progressId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentItem =
          _progressItems.firstWhere((item) => item.id == progressId);
      final updatedItem = await progressApi.apiProgressProgressIdPut(
        progressId: progressId,
        progressItem: ProgressItem(
          id: progressId,
          title: currentItem.title,
          status: status,
          submitTime: currentItem.submitTime,
          details: currentItem.details,
          username: currentItem.username,
        ),
      );
      setState(() {
        final index =
            _progressItems.indexWhere((item) => item.id == progressId);
        if (index != -1) {
          _progressItems[index] = updatedItem;
        }
      });
      _showSuccessSnackBar('状态更新成功！');
    } catch (e) {
      _showErrorSnackBar('更新状态失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProgress(int progressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await progressApi.apiProgressProgressIdDelete(progressId: progressId);
      setState(() {
        _progressItems.removeWhere((item) => item.id == progressId);
      });
      _showSuccessSnackBar('进度删除成功！');
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
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
        content: Text(message,
            style: TextStyle(
                color:
                    controller.currentBodyTheme.value.colorScheme.onPrimary)),
        backgroundColor: controller.currentBodyTheme.value.colorScheme.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnlineProcessingProgress(),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _fetchAllProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Wrap only the theme-dependent part
      final theme = controller.currentBodyTheme.value;
      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              '进度管理',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(theme),
          ),
        ),
      );
    });
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Center(
        child: Text(
          '权限不足：仅管理员可访问此页面',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    if (_progressItems.isEmpty) {
      return Center(
        child: Text(
          '暂无进度记录',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _progressItems.length,
      itemBuilder: (context, index) {
        final item = _progressItems[index];
        return Card(
          elevation: 4,
          color: theme.colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            title: Text(
              item.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '状态: ${item.status}\n提交时间: ${item.submitTime}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _goToDetailPage(item);
                } else if (value == 'delete') {
                  _deleteProgress(item.id);
                } else if (value == 'update_pending') {
                  _updateProgressStatus(item.id, 'Pending');
                } else if (value == 'update_processing') {
                  _updateProgressStatus(item.id, 'Processing');
                } else if (value == 'update_completed') {
                  _updateProgressStatus(item.id, 'Completed');
                } else if (value == 'update_archived') {
                  _updateProgressStatus(item.id, 'Archived');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                const PopupMenuItem<String>(value: 'delete', child: Text('删除')),
                const PopupMenuItem<String>(
                    value: 'update_pending', child: Text('设为待处理')),
                const PopupMenuItem<String>(
                    value: 'update_processing', child: Text('设为处理中')),
                const PopupMenuItem<String>(
                    value: 'update_completed', child: Text('设为已完成')),
                const PopupMenuItem<String>(
                    value: 'update_archived', child: Text('设为已归档')),
              ],
              icon: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () => _goToDetailPage(item),
          ),
        );
      },
    );
  }
}
