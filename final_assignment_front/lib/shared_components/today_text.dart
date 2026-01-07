import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 今天的文本组件
///
/// 显示今天的日期和地点（默认为“哈尔滨”），
/// 并应用毛玻璃效果。
class TodayText extends StatelessWidget {
  final TextStyle? locationStyle;
  final TextStyle? dateStyle;

  const TodayText({super.key, this.locationStyle, this.dateStyle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          // 减小 padding 至 6
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "哈尔滨",
                style: locationStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue[800],
                        ),
              ),
              // 移除 SizedBox，紧凑布局
              Text(
                DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
                style: dateStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
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
