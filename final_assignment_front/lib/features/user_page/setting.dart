import 'package:final_assignment_front/features/user_page/select_text_item.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('…Ë÷√'),
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
        children: [
          SelectTextItem(
            height: 35,
            title: '«Âø’ª∫¥Ê',
            content: '1024k',
            isShowArrow: false,
            textAlign: TextAlign.end,
            contentStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          ),
          SelectTextItem(),
          SelectTextItem(),
          SelectTextItem(),
          SelectTextItem(),
        ],
      ),
    );
  }
}
