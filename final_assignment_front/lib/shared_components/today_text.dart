import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 今天的文本组件
///
/// 显示今天的日期和地点（默认为“哈尔滨”），
/// 并应用毛玻璃效果。修改后卡片采用较高不透明度的白色背景，— 使其在蓝色顶栏下具有更好的对比效果，同时文本使用醒目的颜色。
class TodayText extends StatelessWidget {
  const TodayText({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        // 降低模糊程度，使背景更清晰
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // 使用白色背景但不透明度提高，以保证良好对比
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2), // 灰色阴影，透明度可调
                offset: const Offset(0, 4), // 阴影偏移量
                blurRadius: 4, // 模糊半径
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示地点名称，使用深蓝色确保与蓝色 header 协调且对比足够
              Text(
                "哈尔滨",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue[800],
                    ),
              ),
              const SizedBox(height: 6),
              // 显示今天的日期，使用深灰色
              Text(
                DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
