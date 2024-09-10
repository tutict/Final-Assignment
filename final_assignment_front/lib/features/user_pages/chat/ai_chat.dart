import 'package:flutter/material.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
      title: const Text('智慧助手'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
