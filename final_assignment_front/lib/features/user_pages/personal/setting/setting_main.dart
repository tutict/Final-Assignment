import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkMode = Config.dark;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      Config.dark = value;
      Config.themeData = value ? AppTheme.materialDarkTheme: AppTheme.materialLightTheme;
    });
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
            subtitle: const Text('1024k'),
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
