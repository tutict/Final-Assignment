import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() =>
      _ChangeMobilePhoneNumberState();
}

class _ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  final _phoneController = TextEditingController();
  late DriverInformationControllerApi driverApi;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
  }

  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: const Text('请输入新的手机号码'),
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
    try {
      await driverApi.apiDriversDriverIdPut(
        driverId: '123', // 示例写死，应替换为动态值
        updateValue: 999, // 示例，应替换为实际更新逻辑
      );
      if (!mounted) return;
      Get.back(); // 更新成功后返回
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('成功'),
          content: const Text('手机号码已更新'),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: Text('更新手机号码失败: $e'),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改手机号'), // Material 风格标题
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: ListView(
          children: [
            const Text(
              '修改手机号',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Material 风格蓝色
              ),
            ),
            const SizedBox(height: 16.0), // 与 ManagerSetting.dart 的间距一致
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '请输入新的手机号码',
                border: OutlineInputBorder(), // Material 风格边框
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20.0), // 与 ManagerSetting.dart 的按钮间距一致
            ElevatedButton(
              onPressed: _updatePhoneNumber,
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
