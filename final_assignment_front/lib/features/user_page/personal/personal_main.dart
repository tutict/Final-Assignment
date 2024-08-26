import 'package:flutter/material.dart';

class PersonalMainPage extends StatelessWidget {
  const PersonalMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(tiles: [
          ListTile(
            title: const Text('我的信息'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pushNamed(context, '/personal_info');
            },
          ),
          ListTile(
            title: const Text('账号与安全'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
          ListTile(
            title: const Text('邮寄地址'),
            leading: const Icon(Icons.location_on_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('咨询反馈'),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('智能客服'),
            leading: const Icon(Icons.chat_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('设置'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ]).toList(),
      ),
    );
  }
}
