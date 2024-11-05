import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation consistency

class InformationStatementPage extends StatelessWidget {
  const InformationStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信息申述'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Use Get.back() for consistency if GetX is used for other navigation
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              title: const Text('黑名单手机号码申述'),
              leading: const Icon(Icons.info),
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
            ),
            ListTile(
              title: const Text('黑名单用户申述'),
              leading: const Icon(Icons.info),
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}
