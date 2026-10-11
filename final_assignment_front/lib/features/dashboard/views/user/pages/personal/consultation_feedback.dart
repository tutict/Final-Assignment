// ignore_for_file: use_build_context_synchronously

import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/features/api/feedback_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
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
      final theme = _dashboardController.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: theme,
        title: '咨询与反馈',
        reading: true,
        pageType: DashboardPageType.user,
        onThemeToggle: _dashboardController.toggleBodyTheme,
        footer: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(
                onPressed: _submitFeedback,
                child: const Text('提交反馈'),
              ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSectionHeader(
              title: '请输入您的反馈或咨询内容',
              subtitle: '提交后将由管理员审核处理。',
            ),
            const SizedBox(height: 16),
            DashboardPanel(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '请输入反馈内容...',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
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
  bool _isStaff = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchFeedbackRequests();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isStaff = RoleUtils.canAccessAdminDashboard(prefs.getString('userRole'));
    });
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
    if (!_isStaff) {
      AppSnackbar.showError(context, message: '仅管理员可处理反馈');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _feedbackApi.updateFeedback(
        feedbackId: feedbackId,
        body: {
          'status': status,
        },
      );
      await _fetchFeedbackRequests();
      AppSnackbar.showSuccess(context,
          message: status == 'Resolved' ? '反馈已处理' : '反馈已办结');
    } catch (e) {
      AppSnackbar.showError(context, message: '更新失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = dashboardController.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: theme,
        title: '反馈审批',
        pageType: DashboardPageType.user,
        onThemeToggle: dashboardController.toggleBodyTheme,
        onRefresh: _fetchFeedbackRequests,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        showEmptyState: _feedbackRequests.isEmpty && !_isLoading && _errorMessage.isEmpty,
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _feedbackRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final feedback = _feedbackRequests[index];
            final canAct =
                _isStaff && feedback.status == 'Pending' && feedback.feedbackId != 0;
            return _FeedbackApprovalCard(
              feedback: feedback,
              statusLabel: _translateStatus(feedback.status),
              onApprove: canAct
                  ? () => _updateFeedbackRequest(feedback.feedbackId, 'Resolved')
                  : null,
              onReject: canAct
                  ? () => _updateFeedbackRequest(feedback.feedbackId, 'Completed')
                  : null,
            );
          },
        ),
      );
    });
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Pending':
        return '待处理';
      case 'Processing':
        return '处理中';
      case 'Resolved':
        return '已处理';
      case 'Completed':
        return '已办结';
      default:
        return status;
    }
  }
}

class _FeedbackApprovalCard extends StatelessWidget {
  const _FeedbackApprovalCard({
    required this.feedback,
    required this.statusLabel,
    this.onApprove,
    this.onReject,
  });

  final Feedback feedback;
  final String statusLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPending = feedback.status == 'Pending';
    final statusColor = switch (feedback.status) {
      'Resolved' => const Color(0xFF41B86A),
      'Completed' => scheme.primary,
      'Processing' => const Color(0xFF6B9BD1),
      _ => const Color(0xFFEAB45C),
    };

    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.feedback_outlined,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '用户: ${feedback.username}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.feedback,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          if (isPending && (onApprove != null || onReject != null)) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReject != null)
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('办结'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                    ),
                  ),
                if (onApprove != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('标记已处理'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
