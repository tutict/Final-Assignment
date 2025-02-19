import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalMainPageState();
}

class _PersonalMainPageState extends State<PersonalMainPage> {

  final UserDashboardController controller =
  Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的'),
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
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              CupertinoListTile(
                title: const Text('我的信息'),
                leading: const Icon(CupertinoIcons.person_fill,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.personalInfo);
                },
              ),
              CupertinoListTile(
                title: const Text('账号与安全'),
                leading: const Icon(CupertinoIcons.lock_shield_fill,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.accountAndSecurity);
                },
              ),
              CupertinoListTile(
                title: const Text('咨询反馈'),
                leading: const Icon(CupertinoIcons.conversation_bubble,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.consultation);
                },
              ),
            ],
          ).toList(),
        ),
      ),
    );
  }
}


class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget leading;
  final VoidCallback onTap;

  const CupertinoListTile({
    required this.title,
    required this.leading,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 判断当前主题模式
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 根据当前主题模式设置背景色
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withOpacity(0.7)
              : CupertinoColors.white.withOpacity(0.8),
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