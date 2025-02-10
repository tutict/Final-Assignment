import 'dart:developer';
import 'dart:io';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = 0.0;
  bool _isDarkMode = Config.dark;

  // 获取 DashboardController 实例
  final DashboardController controller = Get.find<DashboardController>();

  /// 切换主题：更新本页面的 _isDarkMode、全局配置以及 DashboardController 中的当前主题
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      Config.dark = value;
      Config.themeData =
          value ? AppTheme.materialDarkTheme : AppTheme.materialLightTheme;
      controller.currentBodyTheme.value = Config.themeData;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateCacheSize(); // 初始化计算缓存大小
  }

  // 计算缓存大小
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

  // 获取目录中所有文件的总大小（单位：MB）
  Future<double> _getTotalSizeOfFilesInDir(final Directory directory) async {
    double totalSize = 0;
    try {
      if (directory.existsSync()) {
        List<FileSystemEntity> files = directory.listSync(recursive: true);
        for (FileSystemEntity file in files) {
          if (file is File) {
            totalSize += await file.length() / (1024 * 1024);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting size of files in directory: $e');
    }
    return totalSize;
  }

  // 清除缓存并重新计算缓存大小
  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    await _calculateCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置'),
        // 使用 CupertinoButton 作为返回按钮，确保点击事件能正常触发
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            log("Back button pressed");
            controller.exitSidebarContent();
            // 重定向到首页，这里使用 Get.offNamed 重置导航栈
            Get.offNamed(Routes.userDashboard);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CupertinoListTile(
                title: const Text('切换白天/夜间模式'),
                trailing: CupertinoSwitch(
                  value: _isDarkMode,
                  onChanged: _toggleTheme,
                ),
                leading: const Icon(
                  CupertinoIcons.moon,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              CupertinoListTile(
                title: const Text('清除缓存'),
                subtitle: Text(
                  '${_cacheSize.toStringAsFixed(2)} MB',
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                ),
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
              const SizedBox(height: 20.0),
              CupertinoButton(
                color: CupertinoColors.systemRed,
                child: const Text('删除账户'),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: const Text('删除账户'),
                        content: const Text('确定要删除账户吗？'),
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
                              Navigator.pop(context);
                            },
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

// CupertinoListTile widget to mimic ListTile for macOS-style design
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
          ),
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
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// 配置暗色模式设置
class Config {
  static bool dark = true;
  static ThemeData themeData = AppTheme.materialDarkTheme;
}
