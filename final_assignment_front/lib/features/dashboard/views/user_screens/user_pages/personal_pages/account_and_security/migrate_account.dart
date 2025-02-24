import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class MigrateAccount extends StatefulWidget {
  const MigrateAccount({super.key});

  @override
  State<MigrateAccount> createState() => _MigrateAccountState();
}

class _MigrateAccountState extends State<MigrateAccount> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final _targetAccountController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitMigration() {
    final targetAccount = _targetAccountController.text.trim();
    final password = _passwordController.text.trim();

    if (targetAccount.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: const Text('请输入目标账号和验证密码'),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // 处理提交逻辑
    debugPrint('Account migration submitted: $targetAccount');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提交成功'),
        content: Text('目标账号: $targetAccount'),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.pop(context);
              controller
                  .navigateToPage(AppPages.accountAndSecurity); // 返回账号与安全页面
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('迁移账号'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            const Text(
              '迁移账号',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Material 风格蓝色
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _targetAccountController,
              decoration: const InputDecoration(
                labelText: '请输入目标账号ID或用户名',
                border: OutlineInputBorder(), // Material 风格边框
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '请输入验证密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            ElevatedButton(
              onPressed: _submitMigration,
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(50), // 全宽按钮，与 ManagerSetting.dart 一致
              ),
              child: const Text('提交'),
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
