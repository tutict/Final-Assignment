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
            title: const Text(''),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pushNamed(context, '/personal_info');
            },
          ),
          ListTile(
            title: const Text(''),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
          ListTile(
            title: const Text(''),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
          ListTile(
            title: const Text(''),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text(''),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text(''),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ]).toList(),
      ),
    );
  }
}
