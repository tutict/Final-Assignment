import 'package:flutter/material.dart';

class ManagerSetting extends StatefulWidget {
  const ManagerSetting({super.key});

  @override
  State<ManagerSetting> createState() => _ManageSettingPage();
}

class _ManageSettingPage extends State<ManagerSetting> {
  bool _notificationEnabled = false;
  bool _darkModeEnabled = false;
  String _serverUrl = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('启用通知'),
              value: _notificationEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('启用深色模式'),
              value: _darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextField(
              decoration: const InputDecoration(
                labelText: '服务器 URL',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  _serverUrl = value;
                });
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // 提交设置的逻辑
                _saveSettings();
              },
              child: const Text('保存设置'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: 将设置保存到本地存储或通过 API 提交到服务器
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置保存成功'),
          content: Text('通知: ${_notificationEnabled ? "已启用" : "已禁用"}\n'
              '深色模式: ${_darkModeEnabled ? "已启用" : "已禁用"}\n'
              '服务器 URL: $_serverUrl'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
