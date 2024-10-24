import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

/// 今天的文本组件
///
/// 该组件用于显示今天的日期和指定地点（默认为哈尔滨）。
/// 它使用了中文格式化日期，并应用了系统默认的中文字体。

class TodayText extends StatelessWidget {
  /// 构造函数
  ///
  /// 初始化TodayText组件，通过super.key传递键值。
  const TodayText({super.key});

  @override
  Widget build(BuildContext context) {
    // 定义一个毛玻璃效果的容器来包裹整个文本内容，限制其最大宽度为220，并添加边距
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
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
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
              ),
              const SizedBox(height: 6),
              // 显示今天日期，格式为“年月日”，如“2023年1月1日”，并设置文本大小为15
              Text(
                DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
