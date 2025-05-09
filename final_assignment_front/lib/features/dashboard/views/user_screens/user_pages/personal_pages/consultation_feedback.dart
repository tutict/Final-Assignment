import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'dart:convert';

class Feedback {
  final int feedbackId; // Changed to non-nullable int
  final String username;
  final String feedback;
  final String status;
  final String timestamp;

  Feedback({
    required this.feedbackId, // Now required
    required this.username,
    required this.feedback,
    required this.status,
    required this.timestamp,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedbackId'] ?? 0,
      // Fallback to 0 if null (shouldn't happen)
      username: json['username'] ?? '',
      feedback: json['feedback'] ?? '',
      status: json['status'] ?? 'Pending',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'username': username,
      'feedback': feedback,
      'status': status,
      'timestamp': timestamp,
    };
  }
}

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State<ConsultationFeedback> createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
      final username = prefs.getString('userName');
      if (jwtToken == null || username == null) {
        throw Exception('No JWT token or username found');
      }

      final apiClient = Get.find<ProgressController>().apiClient;
      final feedbackData = Feedback(
        feedbackId: 0,
        // ID will be assigned by backend
        username: username,
        feedback: feedback,
        status: 'Pending',
        timestamp: DateTime.now().toIso8601String(),
      );

      final response = await apiClient.invokeAPI(
        '/api/feedback',
        'POST',
        [],
        feedbackData.toJson(),
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        {},
        'application/json',
        [],
      );

      if (response.statusCode == 201) {
        _showSuccessDialog('反馈已提交，等待管理员审批');
        _feedbackController.clear();
      } else {
        throw Exception(
            '提交失败: ${jsonDecode(response.body)['error'] ?? '未知错误'}');
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
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
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
        title: const Text('咨询与反馈'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请输入您的反馈或咨询内容：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '请输入反馈内容...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: isLight ? Colors.grey[200] : Colors.grey[800],
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      '提交反馈',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class FeedbackApprovalPage extends StatefulWidget {
  const FeedbackApprovalPage({super.key});

  @override
  State<FeedbackApprovalPage> createState() => _FeedbackApprovalPageState();
}

class _FeedbackApprovalPageState extends State<FeedbackApprovalPage> {
  List<Feedback> _feedbackRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchFeedbackRequests();
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

      final apiClient = Get.find<ProgressController>().apiClient;
      final response = await apiClient.invokeAPI(
        '/api/feedback',
        'GET',
        [],
        '',
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        {},
        null,
        [],
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _feedbackRequests =
              data.map((json) => Feedback.fromJson(json)).toList();
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

  Future<void> _updateFeedbackRequest(int feedbackId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final apiClient = Get.find<ProgressController>().apiClient;
      final response = await apiClient.invokeAPI(
        '/api/feedback/$feedbackId',
        'PUT',
        [],
        {
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        {},
        'application/json',
        [],
      );

      if (response.statusCode == 200) {
        await _fetchFeedbackRequests();
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
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFeedbackRequests,
            tooltip: '刷新反馈列表',
          ),
        ],
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
                                '用户: ${feedback.username}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '反馈: ${feedback.feedback}\n状态: ${_translateStatus(feedback.status)}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              trailing: feedback.status == 'Pending'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green),
                                          onPressed: () {
                                            if (feedback.feedbackId != 0) {
                                              _updateFeedbackRequest(
                                                  feedback.feedbackId,
                                                  'Approved');
                                            } else {
                                              _showErrorSnackBar('无效的反馈ID');
                                            }
                                          },
                                          tooltip: '批准',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red),
                                          onPressed: () {
                                            if (feedback.feedbackId != 0) {
                                              _updateFeedbackRequest(
                                                  feedback.feedbackId,
                                                  'Rejected');
                                            } else {
                                              _showErrorSnackBar('无效的反馈ID');
                                            }
                                          },
                                          tooltip: '拒绝',
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'Pending':
        return '待审批';
      case 'Approved':
        return '已批准';
      case 'Rejected':
        return '已拒绝';
      default:
        return '未知';
    }
  }
}
