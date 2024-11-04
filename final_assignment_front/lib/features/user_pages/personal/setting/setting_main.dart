import 'dart:io';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = 0.0;
  bool _isDarkMode = Config.dark;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      Config.dark = value;
      Config.themeData =
      value ? AppTheme.materialDarkTheme : AppTheme.materialLightTheme;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateCacheSize(); // Initialize cache size calculation
  }

  // Calculate cache size
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

  // Get the total size of files in the cache directory
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

  // Clear cache
  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    await _calculateCacheSize(); // Recalculate size after clearing cache
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('切换白天/夜间模式'),
            value: _isDarkMode,
            onChanged: _toggleTheme,
            secondary: const Icon(Icons.nightlight_round),
          ),
          ListTile(
            title: const Text('清除缓存'),
            subtitle: Text(
              '${_cacheSize.toStringAsFixed(2)} MB',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('清除缓存'),
                    content: const Text('确定要清除缓存吗？'),
                    actions: [
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
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
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(
                width: 1,
                color: Colors.red,
              ),
            ),
            child: const Text('删除账户'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('删除账户'),
                    content: const Text('确定要删除账户吗？'),
                    actions: [
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
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
    );
  }
}

// Configuration for dark mode setting
class Config {
  static bool dark = true;
  static ThemeData themeData = AppTheme.materialDarkTheme;
}
