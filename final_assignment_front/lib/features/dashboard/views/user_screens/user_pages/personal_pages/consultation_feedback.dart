import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final UserDashboardController controller = Get.find<UserDashboardController>();
  final _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '咨询反馈',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(Routes.personalMain);
          },
          child: Icon(
            CupertinoIcons.back,
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
          ),
        ),
        backgroundColor: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.black.withOpacity(0.8),
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // 添加外边距
            padding: const EdgeInsets.all(20.0), // 增加内边距
            decoration: BoxDecoration(
              color: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '咨询反馈',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: _feedbackController,
                  placeholder: '请输入您的反馈...',
                  maxLines: 6,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(10.0),
                    onPressed: () {
                      // TODO: Handle submission logic
                      debugPrint('Feedback submitted: ${_feedbackController.text}');
                    },
                    child: const Text('提交反馈'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}