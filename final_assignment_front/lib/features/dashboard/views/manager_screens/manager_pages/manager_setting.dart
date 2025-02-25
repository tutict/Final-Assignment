import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart'; // 添加 ChatController 导入
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerSetting extends StatefulWidget {
  const ManagerSetting({super.key});

  @override
  State<ManagerSetting> createState() => _ManageSettingPage();
}

class _ManageSettingPage extends State<ManagerSetting> {
  bool _notificationEnabled = false;
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController _themeController = TextEditingController();

  // 统一的 TextStyle，避免插值问题
  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    inherit: true,
  );

  @override
  void initState() {
    super.initState();
    _themeController.text =
        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置管理'),
      ),
      body: Obx(
        () => Theme(
          data: controller.currentBodyTheme.value,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('启用通知'),
                  value: _notificationEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _themeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '选择显示主题',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: _showThemeDialog,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('保存设置', style: _buttonTextStyle),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('登出', style: _buttonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');

    // 清空 AI 聊天页面
    final chatController = Get.find<ChatController>();
    chatController.clearMessages();

    Get.offAllNamed(AppPages.login);
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
}
