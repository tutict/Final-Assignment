import 'package:flutter/cupertino.dart';

class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('修改密码'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
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
            border: Border.all(color: CupertinoColors.systemGrey, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
            color: CupertinoColors.white,
          ),
          child: const Text(
            '修改密码内容', // Placeholder content
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
