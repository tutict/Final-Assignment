import 'package:flutter/cupertino.dart';

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('注销账号'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              border: Border.all(color: CupertinoColors.systemRed, width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '确定要注销账号吗？',
                  style: TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 16.0),
                    CupertinoButton(
                      color: CupertinoColors.systemRed,
                      child: const Text('确定'),
                      onPressed: () {
                        // Perform delete account action
                        Navigator.pop(context);
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
