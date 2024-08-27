import 'package:flutter/material.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('�ҵ���Ϣ'),
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
            title: Text('����'),
            leading: Icon(Icons.person),
          ),
          const ListTile(
            title: Text('ʵ����֤'),
            leading: Icon(Icons.settings),
          ),
          const ListTile(
            title: Text('֤������'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('֤������'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('��Ч����'),
            trailing: Icon(Icons.keyboard_arrow_right),
          ),
          const ListTile(
            title: Text('�ֻ�����'),
            trailing: Icon(Icons.keyboard_arrow_right),
          ),
          const ListTile(
            title: Text('ע��ʱ��'),
            leading: Icon(Icons.logout),
          ),
          const ListTile(
            title: Text('ע���ַ'),
            leading: Icon(Icons.logout),
          ),
        ]).toList(),
      ),
    );
  }
}
