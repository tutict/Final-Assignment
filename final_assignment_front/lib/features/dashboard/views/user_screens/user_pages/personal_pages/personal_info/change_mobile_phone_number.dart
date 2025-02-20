import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() =>
      _ChangeMobilePhoneNumberState();
}

class _ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  // 输入框控制器
  final _phoneController = TextEditingController();

  // 用于与后端交互
  late DriverInformationControllerApi driverApi;

  final UserDashboardController controller =
  Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
  }

  /// 调用后端接口更新手机号码
  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      return; // 简单校验
    }
    try {
      await driverApi.apiDriversDriverIdPut(
        driverId: '123', // 示例写死
        updateValue: 999, // 示例
      );
      if (!mounted) return;
      Navigator.pop(context); // 更新成功后返回
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: Text('更新手机号码失败: $e'),
          actions: [
            CupertinoDialogAction(
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
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : CupertinoColors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '修改手机号', // Theme-dependent text
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _phoneController,
                placeholder: '请输入新的手机号码',
                keyboardType: TextInputType.phone,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isLight
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: CupertinoColors.systemGrey,
                    width: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              CupertinoButton.filled(
                onPressed: _updatePhoneNumber,
                child: const Text('提交'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
