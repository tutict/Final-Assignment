import 'dart:io';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = 0.0;
  final String _selectedTheme = 'Material Light'; // 记录当前选中的主题样式

  final UserDashboardController controller =
      Get.find<UserDashboardController>();

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

  @override
  Widget build(BuildContext context) {
    // 判断当前主题模式
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? Colors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            controller.exitSidebarContent();
            Get.offNamed(Routes.userDashboard);
          },
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      // 使用 BackdropFilter 添加毛玻璃效果
      child: SafeArea(
        child: CupertinoScrollbar(
          child: SingleChildScrollView(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃效果
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.7)
                        : CupertinoColors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // 选择显示主题
                      CupertinoListTile(
                        title: Text(
                          '选择显示主题',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        leading: const Icon(
                          CupertinoIcons.app_badge,
                          color: CupertinoColors.activeBlue,
                        ),
                        trailing: Text(
                          _selectedTheme,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
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
                      CupertinoListTile(
                        title: const Text('清除缓存'),
                        subtitle: Text(
                          '${_cacheSize.toStringAsFixed(2)} MB',
                          style: const TextStyle(
                              color: CupertinoColors.systemGrey),
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
            ),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[850]!.withOpacity(0.6)
              : CupertinoColors.secondarySystemFill.withOpacity(0.3),
          border: const Border(
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
