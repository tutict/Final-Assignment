import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
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

  // 用户管理选项数据
  final List<Map<String, dynamic>> userOptions = [
    // {
    //   'title': '用户列表',
    //   'icon': Icons.group,
    //   'route': const UserList(),
    // },
    // {
    //   'title': '角色管理',
    //   'icon': Icons.admin_panel_settings,
    //   'route': const RoleManagement(),
    // },
  ];

  void _navigateToUserPage(Widget route) {
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
            title: const Text('用户管理菜单'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: userOptions.length,
              itemBuilder: (context, index) {
                final option = userOptions[index];
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
                      onTap: () => _navigateToUserPage(option['route']),
                    ),
                    if (index < userOptions.length - 1)
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