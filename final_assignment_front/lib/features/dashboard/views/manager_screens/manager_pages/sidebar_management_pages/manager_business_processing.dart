import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/appeal_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/deduction_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/driver_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/fine_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/main_process_pages/vehicle_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerBusinessProcessing extends StatefulWidget {
  const ManagerBusinessProcessing({super.key});

  @override
  State<ManagerBusinessProcessing> createState() =>
      _ManagerBusinessProcessingState();
}

class _ManagerBusinessProcessingState extends State<ManagerBusinessProcessing> {
  late DashboardController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<DashboardController>();
    } catch (e) {
      debugPrint('DashboardController not found: $e');
      controller = Get.put(DashboardController()); // Register if not found
    }
  }

  // 业务选项数据
  final List<Map<String, dynamic>> businessOptions = [
    {
      'title': '申诉管理',
      'icon': Icons.gavel,
      'route': const AppealManagementAdmin(),
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
    {
      'title': '违法行为',
      'icon': Icons.warning,
      'route': const OffenseList(),
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
            title: const Text('业务处理菜单'),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
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