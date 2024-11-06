import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// PersonalInformationPage is a StatefulWidget for displaying driver's personal information.
class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      PersonalInformationPageState();
}

/// _PersonalInformationPageState is the state class for PersonalInformationPage.
/// Manages the driver's information and communicates with the server via WebSocket.
class PersonalInformationPageState extends State<PersonalInformationPage> {
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

  /// Loads driver's information from the server.
  /// Sends a request via WebSocket and waits for a response.
  /// On success, updates the state with the driver's information.
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
        debugPrint('Failed to load driver info: ${decodedMessage['message']}');
      }
    } catch (e) {
      debugPrint('Failed to load driver info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('驾驶人信息管理'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: ListView(
            children: [
              CupertinoListTile(
                title: const Text('姓名'),
                subtitle: Text(_driverInfo['name'] ?? '无数据'),
              ),
              CupertinoListTile(
                title: const Text('身份证号'),
                subtitle: Text(_driverInfo['idCardNumber'] ?? '无数据'),
              ),
              CupertinoListTile(
                title: const Text('驾驶证号'),
                subtitle: Text(_driverInfo['licenseNumber'] ?? '无数据'),
              ),
              CupertinoListTile(
                title: const Text('手机号码'),
                subtitle: Text(_driverInfo['phoneNumber'] ?? '无数据'),
                onTap: () {
                  Get.toNamed(AppPages.changeMobilePhoneNumber);
                },
              ),
              CupertinoListTile(
                title: const Text('注册时间'),
                subtitle: Text(_driverInfo['registrationTime'] ?? '无数据'),
              ),
              CupertinoListTile(
                title: const Text('注册地'),
                subtitle: Text(_driverInfo['registrationPlace'] ?? '无数据'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onTap;

  const CupertinoListTile({
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 4.0),
            subtitle,
          ],
        ),
      ),
    );
  }
}
