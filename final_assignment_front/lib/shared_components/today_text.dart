import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 今天的文本组件
///
/// 该组件用于显示今天的日期和指定地点（默认为哈尔滨）。
/// 它使用了中文格式化日期，并应用了系统默认的中文字体。
class TodayText extends StatelessWidget {
  const TodayText({super.key});

  @override
  Widget build(BuildContext context) {
    // 定义一个容器来包裹整个文本内容，限制其最大宽度为200，并添加边距
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        // 设置列布局，使文本从上到下排列
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示地点名称，使用稍大的字体和自定义样式
          Text(
            "哈尔滨",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          // 显示今天日期，格式为“年月日”，如“2023年1月1日”，并设置文本大小为14
          Text(
            DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                )
                .useSystemChineseFont(),
          ),
        ],
      ),
    );
  }
}
