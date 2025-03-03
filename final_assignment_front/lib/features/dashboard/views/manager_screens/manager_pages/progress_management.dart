import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/process_pages/online_processing_progress.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressManagementPage extends StatefulWidget {
  const ProgressManagementPage({super.key});

  @override
  State<ProgressManagementPage> createState() => _ProgressManagementPageState();
}

class _ProgressManagementPageState extends State<ProgressManagementPage> {
  final UserDashboardController controller =
  Get.find<UserDashboardController>();
  List<ProgressItem> _progressItems = [];
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';
  final ProgressControllerApi progressApi = ProgressControllerApi();

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 检查用户角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 更新为后端地址
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
          if (_isAdmin) {
            _fetchAllProgress(); // 仅管理员加载所有进度
          } else {
            _errorMessage = '权限不足：仅管理员可访问此页面';
            _isLoading = false;
          }
        });
      } else {
        setState(() {
          _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = '未登录，请重新登录';
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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await progressApi.apiProgressGet(); // 使用新 API 方法

      setState(() {
        _progressItems = response;
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
      final updatedItem = await progressApi.apiProgressProgressIdPut(
          progressId: progressId,
          progressItem: ProgressItem(
              id: progressId,
              title: '',
              status: status,
              submitTime: '',
              details: null,
              username: '')); // 使用新 API 方法
      setState(() {
        final index = _progressItems.indexWhere((item) => item.id == progressId);
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
      await progressApi.apiProgressProgressIdDelete(
          progressId: progressId); // 使用新 API 方法
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnlineProcessingProgress(), // 使用导入的 ProgressDetailPage
      ),
    ).then((value) {
      if (value == true && mounted) {
        _fetchAllProgress(); // 详情页更新后刷新列表
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
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
            title: const Text('进度管理'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                ),
              ),
            )
                : _progressItems.isEmpty
                ? Center(
              child: Text(
                '暂无进度记录',
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _progressItems.length,
              itemBuilder: (context, index) {
                final item = _progressItems[index];
                return Card(
                  elevation: 4,
                  color: isLight ? Colors.white : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color:
                        isLight ? Colors.black87 : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      '状态: ${item.status}\n提交时间: ${item.submitTime}',
                      style: TextStyle(
                        color:
                        isLight ? Colors.black54 : Colors.white70,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _goToDetailPage(item);
                        } else if (value == 'delete') {
                          _deleteProgress(item.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('编辑'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('删除'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                    ),
                    onTap: () => _goToDetailPage(item),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}