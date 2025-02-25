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
    final chatController = Get.find<ChatController>();
    chatController.clearMessages();
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

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 14.0, // 减小字体大小
    fontWeight: FontWeight.w600,
    color: Colors.white,
    inherit: true,
  );

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
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text('缓存大小'),
                  subtitle: Text(
                      '${_cacheSize >= 0 ? _cacheSize.toStringAsFixed(2) : "计算中..."} MB'),
                  trailing: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _clearCache,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text('清除缓存', style: _buttonTextStyle),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('保存设置', style: _buttonTextStyle),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.exitSidebarContent();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('返回首页', style: _buttonTextStyle),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('登出', style: _buttonTextStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
}
