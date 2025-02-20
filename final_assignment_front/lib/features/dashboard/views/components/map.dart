import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final UserDashboardController controller =
  Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.4), // Adjust background opacity
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '哈尔滨业务点地图', // Theme-dependent text
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.exitSidebarContent();
            Get.offNamed(Routes.userDashboard);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
        isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness:
        isLight ? Brightness.light : Brightness.dark, // Set brightness
      ),
      child: SafeArea(
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(45.803775, 126.534967), // 哈尔滨的经纬度
            initialZoom: 12.0, // 设置缩放级别
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // 使用OpenStreetMap瓦片
              userAgentPackageName: '交通违法行为处理管理系统', // 添加您的应用标识符
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () =>
                      Uri.parse('https://openstreetmap.org/copyright'), // 外部链接
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
