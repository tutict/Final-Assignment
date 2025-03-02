import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() => _ChangeMobilePhoneNumberState();
}

class _ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  final _phoneController = TextEditingController();
  late DriverInformationControllerApi driverApi;
  final UserDashboardController controller = Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
  }

  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: const Text('请输入新的手机号码'),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final driverId = prefs.getString('driverId'); // 假设存储了 driverId
      if (jwtToken == null || driverId == null) {
        throw Exception('No JWT token or driverId found');
      }

      final response = await http.put(
        Uri.parse('http://your-backend-api/api/drivers/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'contactNumber': newPhone, // 假设后端字段为 contactNumber
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Get.back(); // 更新成功后返回
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('成功'),
            content: const Text('手机号码已更新'),
            actions: [
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? '更新手机号码失败';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('错误'),
            content: Text(error),
            actions: [
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('错误'),
          content: Text('更新手机号码失败: $e'),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改手机号'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              '修改手机号',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '请输入新的手机号码',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _updatePhoneNumber,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('提交'),
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}