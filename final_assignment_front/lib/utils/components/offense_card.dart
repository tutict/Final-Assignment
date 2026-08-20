import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// 定义交通违法行为卡片组件
class OffenseCard extends StatelessWidget {
  const OffenseCard({
    required this.data,
    super.key,
  });

  final OffenseCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(kSpacing),
      height: 220,
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: dark ? 0.35 : 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.error.withValues(alpha: dark ? 0.42 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.error.withValues(alpha: dark ? 0.18 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onErrorContainer,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                _OffenseRichText(
                    value1: "${data.totalOffenses}", value2: " 总违法行为"),
                const SizedBox(height: 6),
                _OffenseRichText(
                    value1: "${data.handledOffenses}", value2: " 已处理的违法"),
                const SizedBox(height: 6),
                _OffenseRichText(
                    value1: "${data.unhandledOffenses}", value2: " 未处理的违法"),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _OffenseIndicator(
              total: data.totalOffenses,
              handled: data.handledOffenses,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

// 定义交通违法富文本组件
class _OffenseRichText extends StatelessWidget {
  const _OffenseRichText({
    required this.value1,
    required this.value2,
  });

  final String value1;
  final String value2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium!.copyWith(
          color: scheme.onErrorContainer.withValues(alpha: 0.90),
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: value1),
          TextSpan(
            text: value2,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onErrorContainer.withValues(alpha: 0.70),
              fontWeight: FontWeight.normal,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// 定义交通违法进度指示器组件
class _OffenseIndicator extends StatelessWidget {
  const _OffenseIndicator({
    required this.total,
    required this.handled,
    required this.scheme,
  });

  final int total;
  final int handled;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final double percent = total > 0 ? handled / total : 0.0;

    return CircularPercentIndicator(
      radius: 70,
      lineWidth: 8,
      percent: percent,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${(percent * 100).toStringAsFixed(1)} %",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onErrorContainer,
                  letterSpacing: 0,
                ),
          ),
          Text(
            "处理率",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: scheme.onErrorContainer.withValues(alpha: 0.78),
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
      progressColor: scheme.onErrorContainer.withValues(alpha: 0.92),
      backgroundColor: scheme.onErrorContainer.withAlpha((0.2 * 255).toInt()),
    );
  }
}

// 定义交通违法卡片数据模型
class OffenseCardData {
  final int totalOffenses;
  final int handledOffenses;
  final int unhandledOffenses;
  final String title;

  const OffenseCardData({
    required this.totalOffenses,
    required this.handledOffenses,
    required this.unhandledOffenses,
    required this.title,
  });
}
