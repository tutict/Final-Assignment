import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : CupertinoColors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '咨询反馈', // Theme-dependent text
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.exitSidebarContent();
            Get.offNamed(Routes.userDashboard);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
            isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness:
            isLight ? Brightness.light : Brightness.dark, // Set brightness
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? CupertinoColors.extraLightBackgroundGray
                      : CupertinoColors.systemGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
                child: const CupertinoTextField(
                  placeholder: '请输入您的反馈...',
                  maxLines: 6,
                  padding: EdgeInsets.all(12.0),
                  decoration: null,
                ),
              ),
              const SizedBox(height: 20.0),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(10.0),
                child: const Text('提交反馈'),
                onPressed: () {
                  // Handle submission
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
