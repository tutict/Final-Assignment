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
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '我的', // Theme-dependent text
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
                backgroundColor: isLight
                    ? CupertinoColors.white.withOpacity(0.1)
                    : CupertinoColors.systemGrey3
                        .withOpacity(0.1), // Adjust for light/dark mode
              ),
              CupertinoListTile(
                title: const Text('账号与安全'),
                leading: const Icon(CupertinoIcons.lock_shield_fill,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.accountAndSecurity);
                },
                backgroundColor: isLight
                    ? CupertinoColors.white.withOpacity(0.1)
                    : CupertinoColors.systemGrey3.withOpacity(0.1),
              ),
              CupertinoListTile(
                title: const Text('咨询反馈'),
                leading: const Icon(CupertinoIcons.conversation_bubble,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  controller.navigateToPage(AppPages.consultation);
                },
                backgroundColor: isLight
                    ? CupertinoColors.white.withOpacity(0.1)
                    : CupertinoColors.systemGrey3.withOpacity(0.1),
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
  final Color backgroundColor;

  const CupertinoListTile({
    required this.title,
    required this.leading,
    required this.onTap,
    required this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.0,
              offset: const Offset(0, 2), // Subtle shadow
            ),
          ],
          borderRadius:
              BorderRadius.circular(8.0), // Rounded corners for a modern look
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
