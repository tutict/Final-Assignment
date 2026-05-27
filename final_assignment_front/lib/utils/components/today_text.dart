import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 今天的文本组件
///
/// 显示今天的日期和地点（默认为“哈尔滨”），
/// 并使用当前主题的静态面板样式。
class TodayText extends StatelessWidget {
  final TextStyle? locationStyle;
  final TextStyle? dateStyle;

  const TodayText({super.key, this.locationStyle, this.dateStyle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest
            .withValues(alpha: dark ? 0.42 : 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "哈尔滨",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: locationStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: scheme.onSurface,
                    letterSpacing: 0,
                  ),
            ),
            Text(
              DateFormat.yMMMEd('zh_CN').format(DateTime.now()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dateStyle ??
                  theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
