import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账号与安全'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Using Get.back() for consistency
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
              title: const Text('修改登录密码'),
              leading: const Icon(Icons.person),
              onTap: () {
                Get.toNamed(AppPages.changePassword);
              },
            ),
            ListTile(
              title: const Text('删除账号'),
              leading: const Icon(Icons.delete_outline),
              onTap: () {
                Get.toNamed(AppPages.deleteAccount);
              },
            ),
            ListTile(
              title: const Text('信息申述'),
              leading: const Icon(Icons.report_problem_outlined),
              onTap: () {
                Get.toNamed(AppPages.informationStatement);
              },
            ),
            ListTile(
              title: const Text('迁移账号'),
              leading: const Icon(Icons.transfer_within_a_station_outlined),
              onTap: () {
                Get.toNamed(AppPages.migrateAccount);
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}
