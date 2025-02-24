import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号与安全'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            ListTile(
              title: const Text('修改登录密码'),
              leading: const Icon(Icons.person, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.changePassword);
              },
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('删除账号'),
              leading: const Icon(Icons.delete, color: Colors.red),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.deleteAccount);
              },
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('信息申述'),
              leading: const Icon(Icons.warning, color: Colors.yellow),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.informationStatement);
              },
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('迁移账号'),
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                controller.navigateToPage(AppPages.migrateAccount);
              },
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
}
