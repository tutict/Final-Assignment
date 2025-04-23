import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/fine_information.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/user_appeal.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/vehicle_management.dart';

class BusinessProgressPage extends StatefulWidget {
  const BusinessProgressPage({super.key});

  @override
  State<BusinessProgressPage> createState() => _BusinessProgressPageState();
}

class _BusinessProgressPageState extends State<BusinessProgressPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  // 业务选项数据
  final List<Map<String, dynamic>> businessOptions = [
    {
      'title': '罚款缴纳',
      'icon': Icons.payment,
      'route': const FineInformationPage(),
    },
    {
      'title': '用户申诉',
      'icon': Icons.gavel,
      'route': const UserAppealPage(),
    },
    {
      'title': '车辆登记管理',
      'icon': Icons.directions_car,
      'route': const VehicleManagement(),
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
    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('业务办理菜单'),
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
                      leading: Icon(option['icon'], color: Colors.blue),
                      title: Text(
                        option['title'],
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.grey),
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
