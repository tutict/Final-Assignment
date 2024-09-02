import 'package:flutter/material.dart';


class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('’À∫≈”Î∞≤»´'),
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
            title: const Text('–ﬁ∏ƒµ«¬º√‹¬Î'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pushNamed(context, '/personal_info');
            },
          ),
          ListTile(
            title: const Text('…æ≥˝’À∫≈'),
            leading: const Icon(Icons.location_on_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('«®“∆’À∫≈'),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('–≈œ¢…Í ˆ'),
            leading: const Icon(Icons.chat_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ]).toList(),
      ),
    );
  }
}