import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/appeal_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/deduction_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/driver_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/fine_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/vehicle_list.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

class ManagerBusinessProcessing extends StatefulWidget {
  const ManagerBusinessProcessing({super.key});

  @override
  State<ManagerBusinessProcessing> createState() =>
      _ManagerBusinessProcessingState();
}

class _ManagerBusinessProcessingState extends State<ManagerBusinessProcessing> {
  // 获取 UserDashboardController 以支持动态主题（假设可用）
  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  // 业务选项数据
  final List<Map<String, dynamic>> businessOptions = [
    {
      'title': '申诉管理',
      'icon': Icons.gavel,
      'route': AppealManagementAdmin(appeal: Get.arguments as AppealManagement),
    },
    {
      'title': '扣分管理',
      'icon': Icons.score,
      'route': const DeductionManagement(),
    },
    {
      'title': '司机管理',
      'icon': Icons.person,
      'route': const DriverList(),
    },
    {
      'title': '罚款管理',
      'icon': Icons.payment,
      'route': const FineList(),
    },
    {
      'title': '车辆管理',
      'icon': Icons.directions_car,
      'route': const VehicleList(),
    },
  ];

  void _navigateToBusiness(Widget route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Obx(
      () => Theme(
        data: controller?.currentBodyTheme.value ?? currentTheme,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('业务处理菜单'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: businessOptions.length,
              itemBuilder: (context, index) {
                final option = businessOptions[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        option['icon'],
                        color:
                            isLight ? Colors.blue : Colors.blueAccent, // 适配主题
                      ),
                      title: Text(
                        option['title'],
                        style: TextStyle(
                          color: currentTheme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isLight ? Colors.grey : Colors.grey[400], // 适配主题
                      ),
                      onTap: () => _navigateToBusiness(option['route']),
                    ),
                    if (index < businessOptions.length - 1)
                      const SizedBox(height: 16.0),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
