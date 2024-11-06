import 'package:flutter/cupertino.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation consistency

class InformationStatementPage extends StatelessWidget {
  const InformationStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                  Navigator.pushNamed(context, '/');
                },
              ),
              CupertinoListTile(
                title: const Text('黑名单用户申述'),
                leading: const Icon(CupertinoIcons.info,
                    color: CupertinoColors.activeBlue),
                onTap: () {
                  Navigator.pushNamed(context, '/');
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(
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
