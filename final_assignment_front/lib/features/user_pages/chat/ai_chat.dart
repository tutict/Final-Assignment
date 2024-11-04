import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming GetX is used for navigation consistency

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧助手'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Using GetX for consistency if applicable
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          '智慧助手对话页面',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
