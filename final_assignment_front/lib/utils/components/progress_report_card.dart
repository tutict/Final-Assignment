import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

// 定义进度报告卡片数据模型
class ProgressReportCardData {
  final double percent;
  final String title;
  final int task;
  final int doneTask;
  final int undoneTask;

  const ProgressReportCardData({
    required this.percent,
    required this.title,
    required this.task,
    required this.doneTask,
    required this.undoneTask,
  });
}

// 定义进度报告卡片组件
class ProgressReportCard extends StatelessWidget {
  const ProgressReportCard({
    required this.data,
    super.key,
  });

  final ProgressReportCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(kSpacing),
      height: 220,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: dark ? 0.35 : 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.primary.withValues(alpha: dark ? 0.42 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: dark ? 0.18 : 0.10),
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
                    color: scheme.onPrimaryContainer,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                _ProgressRichText(value1: "${data.task}", value2: " 申诉"),
                const SizedBox(height: 6),
                _ProgressRichText(
                    value1: "${data.doneTask}", value2: " 已处理的申诉"),
                const SizedBox(height: 6),
                _ProgressRichText(
                    value1: "${data.undoneTask}", value2: " 未处理的申诉"),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _Indicator(percent: data.percent, scheme: scheme),
          ),
        ],
      ),
    );
  }
}

// 定义富文本组件，用于显示带有强调的文本
class _ProgressRichText extends StatelessWidget {
  const _ProgressRichText({
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
          color: scheme.onPrimaryContainer.withValues(alpha: 0.90),
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: value1),
          TextSpan(
            text: value2,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.70),
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

// 定义进度指示器组件，用于显示进度百分比
class _Indicator extends StatelessWidget {
  const _Indicator({required this.percent, required this.scheme});

  final double percent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
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
                  color: scheme.onPrimaryContainer,
                  letterSpacing: 0,
                ),
          ),
          Text(
            "完成度",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
      progressColor: scheme.onPrimaryContainer.withValues(alpha: 0.92),
      backgroundColor: scheme.onPrimaryContainer.withAlpha((0.2 * 255).toInt()),
    );
  }
}
