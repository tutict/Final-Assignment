import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  Future<void> _confirmDeletion() async {
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
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final jwtToken = prefs.getString('jwtToken');
                final username = prefs.getString('userName'); // 假设存储了用户名
                if (jwtToken == null || username == null) {
                  throw Exception('No JWT token or username found');
                }

                final response = await http.delete(
                  Uri.parse(
                      'http://your-backend-api/api/users/username/$username'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $jwtToken',
                  },
                );

                if (response.statusCode == 204) {
                  // 204 No Content 表示成功删除
                  // 清除本地存储
                  await prefs.clear();
                  Navigator.pop(context); // 关闭确认对话框
                  Get.back(); // 返回上一页
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('成功'),
                      content: const Text('账号已注销'),
                      actions: [
                        TextButton(
                          child: const Text('确定'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                } else {
                  final error = jsonDecode(response.body)['error'] ?? '账号注销失败';
                  Navigator.pop(context); // 关闭确认对话框
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('错误'),
                      content: Text(error),
                      actions: [
                        TextButton(
                          child: const Text('确定'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // 关闭确认对话框
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('错误'),
                    content: Text('账号注销失败: $e'),
                    actions: [
                      TextButton(
                        child: const Text('确定'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注销账号'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              '注销账号',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              '确定要注销账号吗？\n此操作不可撤销，所有相关数据将被删除。',
              style: TextStyle(
                fontSize: 16.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.navigateToPage(AppPages.accountAndSecurity);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 20.0),
                ElevatedButton(
                  onPressed: _confirmDeletion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor: Colors.red,
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
