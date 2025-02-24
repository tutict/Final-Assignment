import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalMainPageState();
}

class _PersonalMainPageState extends State<PersonalMainPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'), // 与 ManagerSetting.dart 一致的标题样式
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            ListTile(
              title: const Text('我的信息'),
              leading: const Icon(Icons.person, color: Colors.blue),
              // Material 风格图标
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              // Material 风格右侧箭头
              onTap: () {
                controller.navigateToPage(AppPages.personalInfo);
              },
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            ListTile(
              title: const Text('账号与安全'),
              leading: const Icon(Icons.lock, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.accountAndSecurity);
              },
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('咨询反馈'),
              leading: const Icon(Icons.message, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.consultation);
              },
            ),
          ],
        ),
      ),
    );
  }
}
