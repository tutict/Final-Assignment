import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation consistency

class InformationStatementPage extends StatelessWidget {
  const InformationStatementPage({super.key});

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
        middle: const Text('信息申述'),
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
                title: const Text('黑名单手机号码申述'),
                leading: const Icon(CupertinoIcons.info,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  // Modify navigation logic to use GetX for consistency
                  Get.toNamed('/blacklistPhoneAppeal');
                },
              ),
              CupertinoListTile(
                title: const Text('黑名单用户申述'),
                leading: const Icon(CupertinoIcons.info,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  // Modify navigation logic to use GetX for consistency
                  Get.toNamed('/blacklistUserAppeal');
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
  final Widget? leading;
  final VoidCallback? onTap;

  const CupertinoListTile({
    required this.title,
    this.leading,
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
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(child: title),
            const Icon(CupertinoIcons.right_chevron,
                color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }
}
