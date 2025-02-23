import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class InformationStatementPage extends StatefulWidget {
  const InformationStatementPage({super.key});

  @override
  State<InformationStatementPage> createState() => _InformationStatementPageState();
}

class _InformationStatementPageState extends State<InformationStatementPage> {
  final UserDashboardController controller = Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '信息申述',
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
        child: CupertinoScrollbar(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10.0), // 增加整体上下间距
            children: [
              CupertinoListTile(
                title: const Text('黑名单手机号码申述'),
                leading: const Icon(CupertinoIcons.info, color: CupertinoColors.activeBlue),
                onTap: () {
                  Get.toNamed('/blacklistPhoneAppeal');
                },
                backgroundColor: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
              ),
              const SizedBox(height: 10), // 增加选项间距
              CupertinoListTile(
                title: const Text('黑名单用户申述'),
                leading: const Icon(CupertinoIcons.info, color: CupertinoColors.activeBlue),
                onTap: () {
                  Get.toNamed('/blacklistUserAppeal');
                },
                backgroundColor: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
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
  final Widget? leading;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const CupertinoListTile({
    required this.title,
    this.leading,
    this.onTap,
    required this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // 增加垂直内边距
        margin: const EdgeInsets.symmetric(horizontal: 12.0), // 添加左右外边距
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0), // 统一圆角
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isLight ? CupertinoColors.black : CupertinoColors.white,
                  fontSize: 16.0,
                ),
                child: title,
              ),
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: isLight ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
          ],
        ),
      ),
    );
  }
}