import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayText extends StatelessWidget {
  const TodayText({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "哈尔滨",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
            style: const TextStyle(fontSize: 14).useSystemChineseFont(),
          ),
        ],
      ),
    );
  }
}
