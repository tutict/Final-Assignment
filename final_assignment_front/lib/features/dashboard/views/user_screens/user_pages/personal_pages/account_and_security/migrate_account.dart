import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class MigrateAccount extends StatefulWidget {
  const MigrateAccount({super.key});

  @override
  State<MigrateAccount> createState() => _MigrateAccountState();
}

class _MigrateAccountState extends State<MigrateAccount> {
  final controller = Get.find<UserDashboardController>();
  final _targetAccountController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '迁移账号',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(AppPages.accountAndSecurity);
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
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            padding: const EdgeInsets.all(20.0),
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
                  '迁移账号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: _targetAccountController,
                  placeholder: '请输入目标账号ID或用户名',
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 15),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: '请输入验证密码',
                  obscureText: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: CupertinoButton.filled(
                    onPressed: () {
                      debugPrint('Account migration submitted: ${_targetAccountController.text}');
                    },
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