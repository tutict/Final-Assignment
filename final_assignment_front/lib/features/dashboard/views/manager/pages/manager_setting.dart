import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

class ManagerSetting extends StatefulWidget {
  const ManagerSetting({super.key});

  @override
  State<ManagerSetting> createState() => _ManageSettingPage();
}

class _ManageSettingPage extends State<ManagerSetting> {
  bool _notificationEnabled = false;
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController _themeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _themeController.text =
        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthTokenStore.instance.clearJwtToken();
    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      chatController.clearMessages();
    }
    Get.offAllNamed(Routes.login);
  }

  void _saveSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置保存成功'),
          content: Text('通知: ${_notificationEnabled ? "已启用" : "已禁用"}\n'
              '深色模式: ${controller.currentTheme.value == "Dark" ? "已启用" : "已禁用"}\n'
              '当前主题: ${_themeController.text}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择显示主题'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Material Light'),
                  onTap: () {
                    controller.setSelectedStyle('Material');
                    if (controller.currentTheme.value == 'Dark') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Material Dark'),
                  onTap: () {
                    controller.setSelectedStyle('Material');
                    if (controller.currentTheme.value == 'Light') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Ionic Light'),
                  onTap: () {
                    controller.setSelectedStyle('Ionic');
                    if (controller.currentTheme.value == 'Dark') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Ionic Dark'),
                  onTap: () {
                    controller.setSelectedStyle('Ionic');
                    if (controller.currentTheme.value == 'Light') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Basic Light'),
                  onTap: () {
                    controller.setSelectedStyle('Basic');
                    if (controller.currentTheme.value == 'Dark') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Basic Dark'),
                  onTap: () {
                    controller.setSelectedStyle('Basic');
                    if (controller.currentTheme.value == 'Light') {
                      controller.toggleBodyTheme();
                    }
                    _themeController.text =
                        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DashboardPageTemplate(
        theme: controller.currentBodyTheme.value,
        title: '设置管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.blue),
                title: Text(
                  '启用通知',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                subtitle: Text(
                  _notificationEnabled ? '已启用' : '已禁用',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                ),
                trailing: Switch(
                  value: _notificationEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.blue),
                title: Text(
                  '选择显示主题',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                subtitle: Text(
                  _themeController.text,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: _showThemeDialog,
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.save, color: Colors.blue),
                title: Text(
                  '保存设置',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: _saveSettings,
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.blue),
                title: Text(
                  '登出',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('登出'),
                        content: const Text('确定要登出吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              _logout();
                              Navigator.pop(context);
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
