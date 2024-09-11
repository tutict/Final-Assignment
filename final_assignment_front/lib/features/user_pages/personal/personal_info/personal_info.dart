import 'package:final_assignment_front/config/routes/user_routes/user_app_pages.dart';
import 'package:flutter/material.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的信息'),
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
          const ListTile(
            title: Text('姓名'),
          ),
          const ListTile(
            title: Text('是否实名认证'),
          ),
          ListTile(
            title: const Text('手机号码'),
            onTap: () {
              Navigator.pushNamed(context, UserRoutes.changeMobilePhoneNumber);
            },
          ),
          const ListTile(
            title: Text('注册时间'),
          ),
          const ListTile(
            title: Text('注册地'),
          ),
        ]).toList(),
      ),
    );
  }
}
