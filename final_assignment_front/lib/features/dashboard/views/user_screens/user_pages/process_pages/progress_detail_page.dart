import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressDetailPage extends StatefulWidget {
  final ProgressItem item;

  const ProgressDetailPage({super.key, required this.item});

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  late ProgressControllerApi progressApi;
  bool _isLoading = false;
  bool _isAdmin = false; // 确保角色验证
  ProgressItem? _updatedItem;
  final TextEditingController _detailsController = TextEditingController();
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    progressApi = ProgressControllerApi();
    _updatedItem = widget.item;
    _detailsController.text = _updatedItem!.details ?? '';
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'), // 假设后端有此端点验证角色
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      }
    }
  }

  Future<void> _updateProgressStatus(String progressId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      if (!_isAdmin) {
        throw Exception('权限不足：普通用户无法更新进度状态');
      }

      final response = await progressApi.apiProgressProgressIdPut(
          progressId: int.parse(progressId),
          progressItem: _updatedItem!.copyWith(status: status));

      setState(() {
        _updatedItem = response;
        _isLoading = false;
      });
      _showSuccessSnackBar('状态更新成功！');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('更新状态失败: $e');
    }
  }

  Future<void> _deleteProgress(String progressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      if (!_isAdmin) {
        throw Exception('权限不足：普通用户无法删除进度');
      }

      await progressApi.apiProgressProgressIdDelete(
          progressId: int.parse(progressId));
      Navigator.pop(context); // 返回上一页
      _showSuccessSnackBar('进度删除成功！');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('删除失败: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (_isAdmin) {
      // 管理员可以访问，但展示完整功能
    } else {
      // 普通用户只能查看
    }

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('业务详情'),
            backgroundColor: currentTheme.colorScheme.primary,
            foregroundColor: isLight ? Colors.white : Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      ListTile(
                        title: Text('业务ID',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: Text(_updatedItem!.id.toString(),
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                      ),
                      ListTile(
                        title: Text('业务类型',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: Text(_updatedItem!.title,
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                      ),
                      ListTile(
                        title: Text('状态',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: Text(_updatedItem!.status,
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                      ),
                      ListTile(
                        title: Text('提交时间',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: Text(_updatedItem!.submitTime,
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                      ),
                      ListTile(
                        title: Text('详情',
                            style: TextStyle(
                                color: currentTheme.colorScheme.onSurface)),
                        subtitle: TextField(
                          controller: _detailsController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isLight ? Colors.grey : Colors.grey[500]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isLight ? Colors.blue : Colors.blueGrey,
                              ),
                            ),
                          ),
                          maxLines: 3,
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                          enabled: _isAdmin, // 仅管理员可编辑
                        ),
                      ),
                      if (_isAdmin)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _updatedItem!.status,
                              decoration: InputDecoration(
                                labelText: '更新状态',
                                border: const OutlineInputBorder(),
                                labelStyle: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isLight
                                        ? Colors.grey
                                        : Colors.grey[500]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        isLight ? Colors.blue : Colors.blueGrey,
                                  ),
                                ),
                              ),
                              items: [
                                'Pending',
                                'Processing',
                                'Completed',
                                'Archived'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _updateProgressStatus(
                                      _updatedItem!.id.toString(), newValue);
                                }
                              },
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  _deleteProgress(_updatedItem!.id.toString()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: const Text('删除进度'),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}
