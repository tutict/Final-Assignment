import 'dart:io';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/Get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 添加 SharedPreferences 依赖

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = -1.0;
  final String _selectedTheme = 'Material Light';

  final UserDashboardController controller = Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      Directory cacheDir = await getTemporaryDirectory();
      double totalSize = await _getTotalSizeOfFilesInDir(cacheDir);
      setState(() {
        _cacheSize = totalSize;
      });
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
  }

  Future<void> _logout() async {
    // 清除 JWT token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    // 跳转到登录页面
    Get.offAllNamed(AppPages.login); // 假设登录页面路由为 AppPages.login
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '设置',
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.exitSidebarContent();
            Get.offNamed(Routes.userDashboard);
          },
          child: Icon(
            CupertinoIcons.back,
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
          ),
        ),
        backgroundColor: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.black.withOpacity(0.8),
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          children: [
            CupertinoListTile(
              title: const Text('选择显示主题'),
              leading: const Icon(CupertinoIcons.app_badge, color: CupertinoColors.activeBlue),
              trailing: Text(
                _selectedTheme,
                style: TextStyle(
                  color: isLight ? CupertinoColors.black : CupertinoColors.white,
                ),
              ),
              backgroundColor: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: const Text('选择显示主题'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoDialogAction(
                            child: const Text('Material Light'),
                            onPressed: () {
                              controller.setSelectedStyle('Material');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('Material Dark'),
                            onPressed: () {
                              controller.setSelectedStyle('Material');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('Ionic Light'),
                            onPressed: () {
                              controller.setSelectedStyle('Ionic');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('Ionic Dark'),
                            onPressed: () {
                              controller.setSelectedStyle('Ionic');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('Basic Light'),
                            onPressed: () {
                              controller.setSelectedStyle('Basic');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('Basic Dark'),
                            onPressed: () {
                              controller.setSelectedStyle('Basic');
                              controller.toggleBodyTheme();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            CupertinoListTile(
              title: const Text('清除缓存'),
              subtitle: Text(
                '${_cacheSize.toStringAsFixed(2)} MB',
                style: TextStyle(
                  color: isLight ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                ),
              ),
              leading: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed),
              backgroundColor: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: const Text('清除缓存'),
                      content: const Text('确定要清除缓存吗？'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('取消'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          child: const Text('确定'),
                          onPressed: () {
                            _clearCache();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20), // 与上方按钮保持一致的间距
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton(
                color: CupertinoColors.link,
                child: const Text('登出'),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: const Text('登出'),
                        content: const Text('确定要登出吗？'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('取消'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text('确定'),
                            onPressed: () {
                              _logout();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const CupertinoListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    required this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: TextStyle(
                      color: isLight ? CupertinoColors.black : CupertinoColors.white,
                      fontSize: 16.0,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    DefaultTextStyle(
                      style: TextStyle(
                        color: isLight ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                        fontSize: 14.0,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              DefaultTextStyle(
                style: TextStyle(
                  color: isLight ? CupertinoColors.black : CupertinoColors.white,
                  fontSize: 16.0,
                ),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}