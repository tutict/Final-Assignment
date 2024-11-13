import 'package:flutter/cupertino.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() =>
      ChangeMobilePhoneNumberState();
}

class ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('手机号码'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '修改手机号码',
              style: TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
