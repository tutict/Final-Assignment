import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/appeal_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/deduction_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/driver_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/fine_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/vehicle_list.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
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
      () {
        final themeData = controller.currentBodyTheme.value;
        final colorScheme = themeData.colorScheme;
        return DashboardPageTemplate(
          theme: themeData,
          title: '业务处理菜单',
          pageType: DashboardPageType.manager,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          onThemeToggle: controller.toggleBodyTheme,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4 / 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: businessOptions.length,
              itemBuilder: (context, index) {
                final option = businessOptions[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToBusiness(option['route']),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                colorScheme.primaryContainer.withValues(alpha: 0.6),
                            child: Icon(
                              option['icon'],
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            option['title'],
                            style: themeData.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点击进入',
                            style: themeData.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
