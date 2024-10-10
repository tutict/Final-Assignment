import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:flutter/material.dart';

class PersonalMainPage extends StatelessWidget {
  const PersonalMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
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
        children: ListTile.divideTiles(tiles: [
          ListTile(
            title: const Text('我的信息'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pushNamed(context, Routes.personalInfo);
            },
          ),
          ListTile(
            title: const Text('账号与安全'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushNamed(context, Routes.accountAndSecurity);
            },
          ),
          ListTile(
            title: const Text('咨询反馈'),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, Routes.consultation);
            },
          ),
          ListTile(
            title: const Text('智能客服'),
            leading: const Icon(Icons.chat_outlined),
            onTap: () {
              Navigator.pushNamed(context, Routes.aiChat);
            },
          ),
          ListTile(
            title: const Text('设置'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushNamed(context, Routes.setting);
            },
          ),
        ]).toList(),
      ),
    );
  }
}
