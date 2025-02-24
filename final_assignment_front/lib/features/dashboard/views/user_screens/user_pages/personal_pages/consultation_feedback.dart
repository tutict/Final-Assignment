import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class ConsultationFeedback extends StatefulWidget {
  const ConsultationFeedback({super.key});

  @override
  State<ConsultationFeedback> createState() => _ConsultationFeedbackState();
}

class _ConsultationFeedbackState extends State<ConsultationFeedback> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('咨询反馈'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            const Text(
              '咨询反馈',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // 改为 Material 风格的蓝色
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: '请输入您的反馈...',
                border: OutlineInputBorder(), // Material 风格边框
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            ElevatedButton(
              onPressed: () {
                _submitFeedback();
              },
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(50), // 全宽按钮，与 ManagerSetting.dart 一致
              ),
              child: const Text('提交反馈'),
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            ElevatedButton(
              onPressed: () {
                controller.navigateToPage(Routes.personalMain); // 返回个人主页
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                // 全宽按钮，与 ManagerSetting.dart 一致
                backgroundColor: Colors.grey, // 灰色表示返回操作
              ),
              child: const Text('返回上一级'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() {
    // 处理提交逻辑
    debugPrint('Feedback submitted: ${_feedbackController.text}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('反馈提交成功'),
          content: Text('您的反馈: ${_feedbackController.text}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.navigateToPage(Routes.personalMain); // 返回个人页面
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
