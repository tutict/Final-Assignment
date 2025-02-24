import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _submitPasswordChange() {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: const Text('请填写所有密码字段'),
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

    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: const Text('新密码和确认密码不匹配'),
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

    // 处理密码修改逻辑
    debugPrint(
        'Password change submitted: Old: $oldPassword, New: $newPassword');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提交成功'),
        content: const Text('密码已成功修改'),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.pop(context);
              Get.back(); // 返回上一页
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
        title: const Text('修改密码'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            const Text(
              '修改密码',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Material 风格蓝色
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(
                labelText: '旧密码',
                border: OutlineInputBorder(), // Material 风格边框
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            ElevatedButton(
              onPressed: _submitPasswordChange,
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
