import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/appeal_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/deduction_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/driver_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/fine_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/vehicle_list.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
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
      // Fallback if DashboardController isn’t found
      debugPrint('DashboardController not found: $e');
      controller = Get.put(DashboardController()); // Register it if not found
    }
  }

  List<Map<String, dynamic>> _getBusinessOptions() {
    final appealArgument = Get.arguments is AppealManagement
        ? Get.arguments as AppealManagement
        : null;

    return [
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
      }
    ];
  }

  void _navigateToBusiness(Widget route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = controller.currentBodyTheme.value;
      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface, // Dark in dark mode
          appBar: AppBar(
            title: Text(
              '业务处理菜单',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: _getBusinessOptions().length,
              itemBuilder: (context, index) {
                final option = _getBusinessOptions()[index];
                return Column(
                  children: [
                    Card(
                      elevation: 4,
                      color: theme.colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        leading: Icon(
                          option['icon'],
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          option['title'],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onTap: () => _navigateToBusiness(option['route']),
                      ),
                    ),
                    if (index < _getBusinessOptions().length - 1)
                      const SizedBox(height: 16.0),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
