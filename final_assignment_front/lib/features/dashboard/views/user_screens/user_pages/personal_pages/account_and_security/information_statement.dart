import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class InformationStatementPage extends StatefulWidget {
  const InformationStatementPage({super.key});

  @override
  State<InformationStatementPage> createState() =>
      _InformationStatementPageState();
}

class _InformationStatementPageState extends State<InformationStatementPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信息申述'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            ListTile(
              title: const Text('黑名单手机号码申述'),
              leading: const Icon(Icons.info, color: Colors.blue),
              // Material 风格图标
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              // Material 风格右侧箭头
              onTap: () {
                Get.toNamed('/blacklistPhoneAppeal');
              },
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            ListTile(
              title: const Text('黑名单用户申述'),
              leading: const Icon(Icons.info, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Get.toNamed('/blacklistUserAppeal');
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
