import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('·þÎñÍøµã'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        )

    );
  }


  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}