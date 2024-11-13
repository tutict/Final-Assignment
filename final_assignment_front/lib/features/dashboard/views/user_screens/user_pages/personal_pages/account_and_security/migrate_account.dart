import 'package:flutter/cupertino.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation

class MigrateAccount extends StatelessWidget {
  const MigrateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('迁移账号'),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: CupertinoColors.systemGrey, width: 1.0),
          ),
          child: const Text(
            '迁移账号内容',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
