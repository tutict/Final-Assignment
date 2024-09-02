import 'package:flutter/material.dart';

class InformationStatementPage extends StatelessWidget {
  const InformationStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('��Ϣ����'),
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
            title: const Text('��Ϣ����'),
            leading: const Icon(Icons.info),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ]).toList(),
      ),
    );
  }
}