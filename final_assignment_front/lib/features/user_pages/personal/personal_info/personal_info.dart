import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// PersonalInformationPage 是一个 StatefulWidget，用于展示驾驶人的个人信息。
class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

/// _PersonalInformationPageState 是 PersonalInformationPage 的状态类。
/// 它负责管理驾驶人的信息，并通过 WebSocket 与服务器通信以加载信息。
class _PersonalInformationPageState extends State<PersonalInformationPage> {
  late RestApiServices restApiServices;
  Map<String, String> _driverInfo = {
    'name': '加载中...',
    'idCardNumber': '加载中...',
    'licenseNumber': '加载中...',
    'phoneNumber': '加载中...',
    'registrationTime': '加载中...',
    'registrationPlace': '加载中...'
  };

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();
    restApiServices.initWebSocket(AppPages.userInitial);
    _loadDriverInfo();
  }

  /// _loadDriverInfo 方法用于从服务器加载驾驶人的信息。
  /// 它通过 WebSocket 发送请求，并等待服务器的响应。
  /// 响应成功后，更新状态以显示驾驶人的信息。
  Future<void> _loadDriverInfo() async {
    try {
      restApiServices.sendMessage(jsonEncode({'action': 'getDriverInfo'}));
      final response =
          await restApiServices.getMessages().firstWhere((message) {
        final decodedMessage = jsonDecode(message);
        return decodedMessage['action'] == 'getDriverInfoResponse';
      });

      final decodedMessage = jsonDecode(response);
      if (decodedMessage['status'] == 'success') {
        setState(() {
          _driverInfo = Map<String, String>.from(decodedMessage['data']);
        });
      } else {
        debugPrint('加载驾驶人信息失败: ${decodedMessage['message']}');
      }
    } catch (e) {
      debugPrint('加载驾驶人信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('驾驶人信息管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(tiles: [
          ListTile(
            title: const Text('姓名'),
            subtitle: Text(_driverInfo['name'] ?? '无数据'),
          ),
          ListTile(
            title: const Text('身份证号'),
            subtitle: Text(_driverInfo['idCardNumber'] ?? '无数据'),
          ),
          ListTile(
            title: const Text('驾驶证号'),
            subtitle: Text(_driverInfo['licenseNumber'] ?? '无数据'),
          ),
          ListTile(
            title: const Text('手机号码'),
            subtitle: Text(_driverInfo['phoneNumber'] ?? '无数据'),
            onTap: () {
              Get.toNamed(AppPages.changeMobilePhoneNumber);
            },
          ),
          ListTile(
            title: const Text('注册时间'),
            subtitle: Text(_driverInfo['registrationTime'] ?? '无数据'),
          ),
          ListTile(
            title: const Text('注册地'),
            subtitle: Text(_driverInfo['registrationPlace'] ?? '无数据'),
          ),
        ]).toList(),
      ),
    );
  }
}
