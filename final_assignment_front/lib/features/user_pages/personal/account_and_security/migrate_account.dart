import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation

class MigrateAccount extends StatelessWidget {
  const MigrateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('迁移账号'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Use Get.back() for consistency if GetX is used for navigation
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          '迁移账号内容',
          style: TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }
}
