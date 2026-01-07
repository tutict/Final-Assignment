import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ChangeThemes 类是用户用于切换主题的页面。
class ChangeThemes extends StatefulWidget {
  const ChangeThemes({super.key});

  @override
  State<ChangeThemes> createState() => _ChangeThemes();
}

class _ChangeThemes extends State<ChangeThemes> {
  /// 当前选择的主题。
  String selectedTheme = 'basicLight';

  /// 可选择的主题列表。
  final Map<String, ThemeData> themes = {
    'basicLight': AppTheme.basicLight,
    'basicDark': AppTheme.basicDark,
    'ionicLight': AppTheme.ionicLightTheme,
    'ionicDark': AppTheme.ionicDarkTheme,
    'materialLight': AppTheme.materialLightTheme,
    'materialDark': AppTheme.materialDarkTheme,
  };

  /// 切换主题时触发的方法。
  void _toggleTheme(String themeKey) {
    setState(() {
      selectedTheme = themeKey;
      Get.changeTheme(themes[themeKey]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Theme'), // 页面标题
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '选择主题',
              style: TextStyle(fontSize: 24), // 描述文字
            ),
            const SizedBox(height: 20),
            for (String themeKey in themes.keys)
              RadioListTile<String>(
                title: Text(themeKey), // 主题名称
                value: themeKey,
                groupValue: selectedTheme,
                onChanged: (value) {
                  if (value != null) {
                    _toggleTheme(value);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
