import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class InformationStatementPage extends StatefulWidget {
  const InformationStatementPage({super.key});

  @override
  State<InformationStatementPage> createState() =>
      _InformationStatementPageState();
}

class _InformationStatementPageState extends State<InformationStatementPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信息申述'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('黑名单手机号码申述'),
              leading: const Icon(Icons.info, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Get.toNamed('/blacklistPhoneAppeal');
              },
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('黑名单用户申述'),
              leading: const Icon(Icons.info, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Get.toNamed('/blacklistUserAppeal');
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                controller.navigateToPage(Routes.personalMain);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.grey,
              ),
              child: const Text('返回上一级'),
            ),
          ],
        ),
      ),
    );
  }
}
