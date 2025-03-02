import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State<ConsultationFeedback> createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final _feedbackController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false; // 假设从状态管理或 SharedPreferences 获取

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://your-backend-api/api/auth/me'),
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

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      _showErrorDialog('请填写反馈内容');
      return;
    }

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

      final response = await http.post(
        Uri.parse('http://your-backend-api/api/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'username': username,
          'feedback': feedback,
          'status': 'Pending', // 初始状态为待审批
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        // 201 Created 表示成功创建请求
        _showSuccessDialog('反馈已提交，等待管理员审批');
        _feedbackController.clear();
      } else {
        throw Exception(
            '提交失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorDialog('提交反馈失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提交成功'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.pop(context);
              controller.navigateToPage(Routes.personalMain);
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('咨询反馈'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Text(
                    '咨询反馈',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isLight ? Colors.blue : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: '请输入您的反馈...',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isLight ? Colors.grey : Colors.grey[500]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isLight ? Colors.blue : Colors.blueGrey,
                        ),
                      ),
                    ),
                    maxLines: 6,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('提交反馈'),
                  ),
                  const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
                  ElevatedButton(
                    onPressed: () {
                      controller.navigateToPage(Routes.personalMain);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.grey,
                      foregroundColor: isLight ? Colors.black87 : Colors.white,
                    ),
                    child: const Text('返回上一级'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}

class FeedbackApprovalPage extends StatefulWidget {
  const FeedbackApprovalPage({super.key});

  @override
  State<FeedbackApprovalPage> createState() => _FeedbackApprovalPageState();
}

class _FeedbackApprovalPageState extends State<FeedbackApprovalPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  List<Map<String, dynamic>> _feedbackRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFeedbackRequests();
  }

  Future<void> _fetchFeedbackRequests() async {
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

      final response = await http.get(
        Uri.parse('http://your-backend-api/api/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _feedbackRequests = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('加载反馈请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载反馈请求失败: $e';
      });
    }
  }

  Future<void> _updateFeedbackRequest(String feedbackId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.put(
        Uri.parse('http://your-backend-api/api/feedback/$feedbackId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _fetchFeedbackRequests(); // 刷新列表
        _showSuccessSnackBar('反馈已${status == 'Approved' ? '批准' : '拒绝'}');
      } else {
        throw Exception('更新失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('更新失败: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈审批'),
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
                : _feedbackRequests.isEmpty
                    ? Center(
                        child: Text(
                          '暂无反馈请求',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _feedbackRequests.length,
                        itemBuilder: (context, index) {
                          final feedback = _feedbackRequests[index];
                          return Card(
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                '用户: ${feedback['username']}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '反馈: ${feedback['feedback']}\n状态: ${feedback['status'] ?? 'Pending'}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () => _updateFeedbackRequest(
                                        feedback['feedbackId'].toString(),
                                        'Approved'),
                                    tooltip: '批准',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () => _updateFeedbackRequest(
                                        feedback['feedbackId'].toString(),
                                        'Rejected'),
                                    tooltip: '拒绝',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
