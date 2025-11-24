import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/log_pages/login_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/log_pages/operation_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/log_pages/system_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/widgets/dashboard_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogManagement extends StatefulWidget {
  const LogManagement({super.key});

  @override
  State<LogManagement> createState() => _LogManagementState();
}

class _LogManagementState extends State<LogManagement> {
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

  // 日志管理选项数据
  final List<Map<String, dynamic>> logOptions = [
    {
      'title': '登录日志',
      'icon': Icons.login_rounded,
      'route': const LoginLogPage(),
    },
    {
      'title': '操作日志',
      'icon': Icons.history,
      'route': const OperationLogPage(),
    },
    {
      'title': '系统日志',
      'icon': Icons.book_outlined,
      'route': const SystemLogPage(),
    },
  ];

  void _navigateToLogPage(Widget route) {
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
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: DashboardPageAppBar(
            theme: themeData,
            title: '日志管理菜单',
            onThemeToggle: controller.toggleBodyTheme,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: logOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = logOptions[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: colorScheme.surfaceContainer,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(option['icon'],
                          color: colorScheme.onPrimaryContainer),
                    ),
                    title: Text(
                      option['title'],
                      style: themeData.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onTap: () => _navigateToLogPage(option['route']),
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
