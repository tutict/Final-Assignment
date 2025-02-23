import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// PersonalInformationPage is a StatefulWidget for displaying driver's personal information.
class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

/// _PersonalInformationPageState is the state class for PersonalInformationPage.
/// It manages the driver's information via DriverInformationControllerApi.
class _PersonalInformationPageState extends State<PersonalInformationPage> {
  // 用于与后端交互的API
  late DriverInformationControllerApi driverApi;

  // Future 用于异步加载司机信息
  late Future<DriverInformation?> _driverFuture;

  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();

    // 加载某个 driverId 的信息，演示写死 '123'，请按实际获取方式处理
    _driverFuture = _fetchDriverInfo('123');
  }

  /// 异步加载某个driverId的驾驶员信息
  Future<DriverInformation?> _fetchDriverInfo(String driverId) async {
    try {
      // 调用 controllerApi 获取
      final response =
          await driverApi.apiDriversDriverIdGet(driverId: driverId);
      if (response == null) return null;

      if (response is Map<String, dynamic>) {
        // 后端若返回单个对象
        return DriverInformation.fromJson(response);
      }
      // 如果后端返回的不是Map，可能是 List 或其他，按需求处理
      return null;
    } catch (e) {
      // 处理或打印错误
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : CupertinoColors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '驾驶人信息管理', // Theme-dependent text
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.navigateToPage(Routes.personalMain);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
            isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness:
            isLight ? Brightness.light : Brightness.dark, // Set brightness
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: FutureBuilder<DriverInformation?>(
            future: _driverFuture,
            builder: (context, snapshot) {
              // 正在加载
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              // 出错
              else if (snapshot.hasError) {
                return Center(
                  child: Text('加载驾驶人信息失败: ${snapshot.error}'),
                );
              }
              // 无数据
              else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('没有找到驾驶人信息'),
                );
              }
              // 成功
              else {
                final driverInfo = snapshot.data!;
                return _buildDriverInfoList(driverInfo);
              }
            },
          ),
        ),
      ),
    );
  }

  /// 构建驾驶人信息的列表
  Widget _buildDriverInfoList(DriverInformation driverInfo) {
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
          subtitle: Text(driverInfo.driverLicenseNumber ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('手机号码'),
          subtitle: Text(driverInfo.contactNumber ?? '无数据'),
          onTap: () {
            // 导航到修改手机号码的页面
            Navigator.pushNamed(context, AppPages.changeMobilePhoneNumber);
          },
        ),
        CupertinoListTile(
          title: const Text('首次领证日期'),
          subtitle: Text(driverInfo.firstLicenseDate ?? '无数据'),
        ),
        CupertinoListTile(
          title: const Text('准驾车型'),
          subtitle: Text(driverInfo.allowedVehicleType ?? '无数据'),
        ),
      ],
    );
  }
}

/// 一个简单的 Cupertino风格列表组件
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
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isLight
              ? CupertinoColors.white.withOpacity(0.9)
              : CupertinoColors.systemGrey.withOpacity(0.2),
          border: const Border(
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
