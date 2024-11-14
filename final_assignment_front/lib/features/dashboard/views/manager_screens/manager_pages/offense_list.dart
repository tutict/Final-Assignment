import 'package:flutter/material.dart';

class OffenseList extends StatefulWidget {
  const OffenseList({super.key});

  @override
  State<OffenseList> createState() => _OffenseListPage();
}

class _OffenseListPage extends State<OffenseList> {
  final List<String> _offenses = [
    '闯红灯',
    '超速驾驶',
    '违章停车',
    '未系安全带',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交通违法行为列表'),
      ),
      body: ListView.builder(
        itemCount: _offenses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_offenses[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _offenses.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }
}
