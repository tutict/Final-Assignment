import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  void _confirmDeletion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text('确定要注销账号吗？\n此操作不可撤销，所有相关数据将被删除。'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // 处理删除账号逻辑
              debugPrint('Account deletion confirmed');
              Navigator.pop(context);
              Get.back(); // 返回上一页
            },
            child: const Text('确定'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注销账号'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            const Text(
              '注销账号',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red, // 使用红色突出警告，与 ManagerSetting.dart 风格一致
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            const Text(
              '确定要注销账号吗？\n此操作不可撤销，所有相关数据将被删除。',
              style: TextStyle(
                fontSize: 16.0,
                height: 1.5, // 增加行距
              ),
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.navigateToPage(AppPages.accountAndSecurity);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50), // 设置按钮宽度和高度
                    backgroundColor: Colors.grey, // 取消按钮为灰色
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 20.0), // 按钮间距
                ElevatedButton(
                  onPressed: _confirmDeletion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50), // 设置按钮宽度和高度
                    backgroundColor: Colors.red, // 确定按钮为红色
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
