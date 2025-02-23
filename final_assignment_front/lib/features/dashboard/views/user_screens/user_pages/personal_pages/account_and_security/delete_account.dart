import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart'; // 添加 GetX 支持，与之前一致

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final UserDashboardController controller = Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '注销账号',
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
                  '注销账号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemRed, // 使用红色突出警告
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '确定要注销账号吗？\n此操作不可撤销，所有相关数据将被删除。',
                  style: TextStyle(
                    fontSize: 16.0,
                    height: 1.5, // 增加行距
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      color: isLight ? CupertinoColors.systemGrey4 : CupertinoColors.systemGrey,
                      child: const Text('取消'),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    const SizedBox(width: 20.0),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      color: CupertinoColors.systemRed,
                      child: const Text('确定'),
                      onPressed: () {
                        // TODO: Perform delete account action
                        debugPrint('Account deletion confirmed');
                        Get.back();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}