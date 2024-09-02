import 'package:flutter/material.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手机号码'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('修改手机号码'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              }, child: null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}