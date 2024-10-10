import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = 0.0;
  bool _isDarkMode = Config.dark;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      Config.dark = value;
      Config.themeData = value ? AppTheme.materialDarkTheme: AppTheme.materialLightTheme;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateCacheSize(); // 初始化时计算缓存大小
  }

  // 计算缓存大小
  Future<void> _calculateCacheSize() async {
    List<FileInfo> cacheFiles = (DefaultCacheManager().getFileFromCache) as List<FileInfo>;
    double totalSize = 0;

    for (var cacheItem in cacheFiles) {
      File file = cacheItem.file;    // 获取文件对象
      if (await file.exists()) {
        totalSize += await file.length() / (1024 * 1024);    // MB
      }
    }

    setState(() {
      _cacheSize = totalSize;
    });
  }

  // 清理缓存
  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    _calculateCacheSize(); // 清理缓存后重新计算大小
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
            onPressed: () {
            },
            child: const Text('删除账户'),
          ),
        ],
      ),
    );
  }
}

class Config {
  static bool dark = true;
  static ThemeData themeData = AppTheme.materialDarkTheme;
}

