import 'package:flutter/material.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的信息'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(tiles: [
          const ListTile(
            title: Text('姓名'),
            leading: Icon(Icons.person),
          ),
          const ListTile(
            title: Text('实名认证'),
            leading: Icon(Icons.settings),
          ),
          const ListTile(
            title: Text('证件类型'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('证件号码'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('有效期限'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('手机号码'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('注册时间'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('注册地址'),
            leading: Icon(Icons.logout),
          ),
        ]).toList(),
      ),
    );
  }
}
