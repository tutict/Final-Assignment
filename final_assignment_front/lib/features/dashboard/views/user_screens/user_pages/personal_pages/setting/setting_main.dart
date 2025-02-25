import 'dart:io';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/Get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = -1.0;
  final TextEditingController _themeController = TextEditingController();
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
    _themeController.text =
        '${controller.selectedStyle.value} ${controller.currentTheme.value}';
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _calculateCacheSize() async {
    try {
      Directory cacheDir = await getTemporaryDirectory();
      double totalSize = await _getTotalSizeOfFilesInDir(cacheDir);
      if (mounted) {
        setState(() {
          _cacheSize = totalSize;
        });
      }
    } catch (e) {
      debugPrint('Failed to calculate cache size: $e');
    }
  }

  Future<double> _getTotalSizeOfFilesInDir(final Directory directory) async {
    double totalSize = 0;
    try {
      if (directory.existsSync()) {
        List<FileSystemEntity> files = directory.listSync(recursive: true);
        for (FileSystemEntity file in files) {
          if (file is File) {
            totalSize += await file.length() / (1024 * 1024); // Size in MB
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting size of files in directory: $e');
    }
    return totalSize;
  }

  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    await _calculateCacheSize();
    _showSuccessDialog('缓存已清除');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      chatController.clearMessages();
    }
    Get.offAllNamed(AppPages.login);
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('操作成功'),
          content: Text('$message\n'
              '深色模式: ${controller.currentTheme.value == "Dark" ? "已启用" : "已禁用"}\n'
              '当前主题: ${_themeController.text}\n'
              '缓存大小: ${_cacheSize.toStringAsFixed(2)} MB'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.exitSidebarContent();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    _showSuccessDialog('设置已保存');
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
                            .withOpacity(0.7)),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: _showThemeDialog,
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.storage, color: Colors.blue),
                  title: Text(
                    '清除缓存',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '${_cacheSize >= 0 ? _cacheSize.toStringAsFixed(2) : "计算中..."} MB',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: _clearCache,
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
                  leading: const Icon(Icons.home, color: Colors.blue),
                  title: Text(
                    '返回首页',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    controller.exitSidebarContent();
                  },
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
      ),
    );
  }
}
