// ignore_for_file: use_build_context_synchronously

import 'package:final_assignment_front/features/api/feedback_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/widgets/user_page_app_bar.dart';
import 'package:final_assignment_front/utils/widgets/index.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Feedback {
  final int feedbackId;
  final String username;
  final String feedback;
  final String status;
  final String timestamp;

  Feedback({
    required this.feedbackId,
    required this.username,
    required this.feedback,
    required this.status,
    required this.timestamp,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedbackId'] ?? 0,
      username: json['username'] ?? '',
      feedback: json['feedback'] ?? '',
      status: json['status'] ?? 'Pending',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'feedbackId': feedbackId,
        'username': username,
        'feedback': feedback,
        'status': status,
        'timestamp': timestamp,
      };
}

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State<ConsultationFeedback> createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final TextEditingController _feedbackController = TextEditingController();
  final FeedbackControllerApi _feedbackApi = FeedbackControllerApi();
  final UserDashboardController _dashboardController =
      Get.find<UserDashboardController>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty) {
      AppSnackbar.showError(context, message: '请填写反馈内容');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('userName');
      if (username == null) {
        throw Exception('未找到登录信息，请重新登录');
      }

      final feedbackData = Feedback(
        feedbackId: 0,
        username: username,
        feedback: feedbackText,
        status: 'Pending',
        timestamp: DateTime.now().toIso8601String(),
      );

      await _feedbackApi.createFeedback(body: feedbackData.toJson());
      AppDialog.showConfirmDialog(
        context: context,
        title: '成功',
        message: '反馈已提交，等待管理员审核',
        confirmText: '知道了',
      );
      _feedbackController.clear();
    } catch (e) {
      AppSnackbar.showError(context, message: '提交反馈失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = _dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: UserPageAppBar(
          theme: themeData,
          title: '咨询与反馈',
          onThemeToggle: _dashboardController.toggleBodyTheme,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请输入您的反馈或咨询内容：',
                style: themeData.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '请输入反馈内容...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainer,
                ),
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const LoadingView()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '提交反馈',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    });
  }
}

class FeedbackApprovalPage extends StatefulWidget {
  const FeedbackApprovalPage({super.key});

  @override
  State<FeedbackApprovalPage> createState() => _FeedbackApprovalPageState();
}

class _FeedbackApprovalPageState extends State<FeedbackApprovalPage> {
  final List<Feedback> _feedbackRequests = [];
  final FeedbackControllerApi _feedbackApi = FeedbackControllerApi();
  final UserDashboardController dashboardController =
      Get.find<UserDashboardController>();
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
      final data = await _feedbackApi.listFeedback();
      setState(() {
        _feedbackRequests
          ..clear()
          ..addAll(data.map(Feedback.fromJson));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载反馈请求失败: $e';
      });
    }
  }

  Future<void> _updateFeedbackRequest(int feedbackId, String status) async {
    setState(() => _isLoading = true);
    try {
      await _feedbackApi.updateFeedback(
        feedbackId: feedbackId,
        body: {
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _fetchFeedbackRequests();
      AppSnackbar.showSuccess(context,
          message: '反馈已${status == 'Approved' ? '批准' : '拒绝'}');
    } catch (e) {
      AppSnackbar.showError(context, message: '更新失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: UserPageAppBar(
          theme: themeData,
          title: '反馈审批',
          onThemeToggle: dashboardController.toggleBodyTheme,
          onRefresh: _fetchFeedbackRequests,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const LoadingView()
              : _errorMessage.isNotEmpty
                  ? ErrorStateView(
                      message: _errorMessage,
                      onRetry: _fetchFeedbackRequests,
                    )
                  : _feedbackRequests.isEmpty
                      ? const EmptyStateView(
                          message: '暂无反馈请求',
                          icon: Icons.feedback_outlined,
                        )
                      : ListView.builder(
                          itemCount: _feedbackRequests.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbackRequests[index];
                            return Card(
                              elevation: 3,
                              color: themeData.colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  '用户: ${feedback.username}',
                                  style:
                                      themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '反馈: ${feedback.feedback}\n状态: ${_translateStatus(feedback.status)}',
                                  style:
                                      themeData.textTheme.bodyMedium?.copyWith(
                                    color:
                                        themeData.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: feedback.status == 'Pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.check,
                                                color: themeData
                                                    .colorScheme.primary),
                                            onPressed: () {
                                              if (feedback.feedbackId != 0) {
                                                _updateFeedbackRequest(
                                                    feedback.feedbackId,
                                                    'Approved');
                                              } else {
                                                AppSnackbar.showError(context,
                                                    message: '无效的反馈ID');
                                              }
                                            },
                                            tooltip: '批准',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close,
                                                color: themeData
                                                    .colorScheme.error),
                                            onPressed: () {
                                              if (feedback.feedbackId != 0) {
                                                _updateFeedbackRequest(
                                                    feedback.feedbackId,
                                                    'Rejected');
                                              } else {
                                                AppSnackbar.showError(context,
                                                    message: '无效的反馈ID');
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
    });
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Pending':
        return '待审核';
      case 'Approved':
        return '已批准';
      case 'Rejected':
        return '已拒绝';
      default:
        return '未知';
    }
  }
}
