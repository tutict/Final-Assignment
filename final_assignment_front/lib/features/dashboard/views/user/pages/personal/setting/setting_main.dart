import 'dart:io';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/Get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

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
    _showSuccessDialog('ç¼å­å·²æ¸
é¤');
  }

  Future<void> _logout() async {
    await AuthTokenStore.instance.clearJwtToken();
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
          title: const Text('æä½æå'),
          content: Text('$message\n'
              'æ·±è²æ¨¡å¼: ${controller.currentTheme.value == "Dark" ? "å·²å¯ç¨" : "å·²ç¦ç¨"}\n'
              'å½åä¸»é¢: ${_themeController.text}\n'
              'ç¼å­å¤§å°: ${_cacheSize.toStringAsFixed(2)} MB'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.exitSidebarContent();
              },
              child: const Text('ç¡®å®'),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    _showSuccessDialog('è®¾ç½®å·²ä¿å­');
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('éæ©æ¾ç¤ºä¸»é¢'),
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
              child: const Text('åæ¶'),
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
        title: const Text('è®¾ç½®ç®¡ç'),
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
                    'éæ©æ¾ç¤ºä¸»é¢',
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
                  leading: const Icon(Icons.storage, color: Colors.blue),
                  title: Text(
                    'æ¸
é¤ç¼å­',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '${_cacheSize >= 0 ? _cacheSize.toStringAsFixed(2) : "è®¡ç®ä¸­..."} MB',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: _clearCache,
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.save, color: Colors.blue),
                  title: Text(
                    'ä¿å­è®¾ç½®',
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
                    'è¿åé¦é¡µ',
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
                  leading: const Icon(Icons.home, color: Colors.blue),
                  title: Text(
                    'åé¦',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  trailing:
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    controller.navigateToPage(Routes.consultation);
                  },
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.blue),
                  title: Text(
                    'ç»åº',
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
                          title: const Text('ç»åº'),
                          content: const Text('ç¡®å®è¦ç»åºåï¼'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('åæ¶'),
                            ),
                            TextButton(
                              onPressed: () {
                                _logout();
                                Navigator.pop(context);
                              },
                              child: const Text('ç¡®å®'),
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
