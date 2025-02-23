import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() => _ChangeMobilePhoneNumberState();
}

class _ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  final _phoneController = TextEditingController();
  late DriverInformationControllerApi driverApi;
  final UserDashboardController controller = Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
  }

  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: const Text('请输入新的手机号码'),
          actions: [
            CupertinoDialogAction(
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
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '修改手机号',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(AppPages.personalMain);
          },
          child: Icon(
            CupertinoIcons.back,
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
          ),
        ),
        backgroundColor: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.black.withOpacity(0.8),
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // 添加外边距
            padding: const EdgeInsets.all(20.0), // 增加内边距
            decoration: BoxDecoration(
              color: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '修改手机号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: _phoneController,
                  placeholder: '请输入新的手机号码',
                  keyboardType: TextInputType.phone,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: CupertinoButton.filled(
                    onPressed: _updatePhoneNumber,
                    child: const Text('提交'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}