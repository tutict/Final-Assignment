import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDashboardController>();

    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : CupertinoColors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: const Text('账号与安全'),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: ListView(
            children: [
              CupertinoListTile(
                title: const Text('修改登录密码'),
                leading: const Icon(CupertinoIcons.person_fill,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.changePassword);
                },
              ),
              CupertinoListTile(
                title: const Text('删除账号'),
                leading: const Icon(CupertinoIcons.delete,
                    color: CupertinoColors.destructiveRed),
                onTap: () {
                  controller.navigateToPage(AppPages.deleteAccount);
                },
              ),
              CupertinoListTile(
                title: const Text('信息申述'),
                leading: const Icon(CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.systemYellow),
                onTap: () {
                  controller.navigateToPage(AppPages.informationStatement);
                },
              ),
              CupertinoListTile(
                title: const Text('迁移账号'),
                leading: const Icon(CupertinoIcons.arrow_right_arrow_left,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.migrateAccount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget leading;
  final VoidCallback? onTap;

  const CupertinoListTile({
    required this.title,
    required this.leading,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isLight
              ? CupertinoColors.white.withOpacity(0.9)
              : CupertinoColors.systemGrey.withOpacity(0.2),
          border: const Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16.0),
            Expanded(child: title),
            const Icon(CupertinoIcons.right_chevron,
                color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }
}
