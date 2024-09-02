import 'package:flutter/material.dart';

class ConsultationFeedback extends StatelessWidget {
  const ConsultationFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('×ÉÑ¯·´À¡'),
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
      )
    );
  }
}