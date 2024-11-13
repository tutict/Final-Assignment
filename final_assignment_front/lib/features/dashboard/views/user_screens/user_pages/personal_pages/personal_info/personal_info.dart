import 'dart:convert';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';

/// PersonalInformationPage is a StatefulWidget for displaying driver's personal information.
class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

/// _PersonalInformationPageState is the state class for PersonalInformationPage.
/// Manages the driver's information and communicates with the server via WebSocket.
class _PersonalInformationPageState extends State<PersonalInformationPage> {
  late RestApiServices restApiServices;

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    // 初始化 WebSocket 连接，并传入 MessageProvider
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    restApiServices.initWebSocket(AppPages.userInitial, messageProvider);

    // 发送获取驾驶人信息的请求
    restApiServices.sendMessage(jsonEncode({'action': 'getDriverInfo'}));
  }

  @override
  void dispose() {
    // 关闭 WebSocket 连接
    restApiServices.closeWebSocket();
    super.dispose();
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
          child: Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
              final message = messageProvider.message;
              if (message != null &&
                  message.action == 'getDriverInfoResponse') {
                if (message.data['status'] == 'success') {
                  final driverInfo = DriverInfo.fromJson(message.data['data']);
                  return _buildDriverInfoList(driverInfo);
                } else {
                  return Center(
                    child: Text('加载驾驶人信息失败: ${message.data['message']}'),
                  );
                }
              } else {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoList(DriverInfo driverInfo) {
    return ListView(
      children: [
        CupertinoListTile(
          title: const Text('姓名'),
          subtitle: Text(driverInfo.name ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('身份证号'),
          subtitle: Text(driverInfo.idCardNumber ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('驾驶证号'),
          subtitle: Text(driverInfo.licenseNumber ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('手机号码'),
          subtitle: Text(driverInfo.phoneNumber ?? '无数据'),
          onTap: () {
            // 导航到修改手机号码的页面
            Navigator.pushNamed(context, AppPages.changeMobilePhoneNumber);
          },
        ),
        CupertinoListTile(
          title: const Text('注册时间'),
          subtitle: Text(driverInfo.registrationTime ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('注册地'),
          subtitle: Text(driverInfo.registrationPlace ?? '无数据'),
        ),
      ],
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

/// 驾驶人信息模型
class DriverInfo {
  String? name;
  String? idCardNumber;
  String? licenseNumber;
  String? phoneNumber;
  String? registrationTime;
  String? registrationPlace;

  DriverInfo({
    this.name,
    this.idCardNumber,
    this.licenseNumber,
    this.phoneNumber,
    this.registrationTime,
    this.registrationPlace,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'],
      idCardNumber: json['idCardNumber'],
      licenseNumber: json['licenseNumber'],
      phoneNumber: json['phoneNumber'],
      registrationTime: json['registrationTime'],
      registrationPlace: json['registrationPlace'],
    );
  }
}
