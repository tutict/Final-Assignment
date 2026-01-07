import 'package:chinese_font_library/chinese_font_library.dart';
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(kSpacing),
      height: 220, // 保持固定高度
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isLight
                ? const Color.fromRGBO(111, 88, 255, 1)
                : const Color.fromRGBO(63, 40, 207, 1),
            isLight
                ? const Color.fromRGBO(157, 86, 248, 1)
                : const Color.fromRGBO(107, 66, 198, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.1 : 0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min, // 限制高度为最小值
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )
                      .useSystemChineseFont(),
                ),
                const SizedBox(height: 8), // 减少间距
                _RichText(value1: "${data.task}", value2: " 申诉"),
                const SizedBox(height: 6), // 减少间距
                _RichText(value1: "${data.doneTask}", value2: " 已处理的申诉"),
                const SizedBox(height: 6), // 减少间距
                _RichText(value1: "${data.undoneTask}", value2: " 未处理的申诉"),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _Indicator(percent: data.percent, isLight: isLight),
          ),
        ],
      ),
    );
  }
}

// 定义富文本组件，用于显示带有强调的文本
class _RichText extends StatelessWidget {
  const _RichText({
    required this.value1,
    required this.value2,
  });

  final String value1;
  final String value2;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: isLight ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14, // 减小字体大小
            ),
        children: [
          TextSpan(text: value1),
          TextSpan(
            text: value2,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isLight ? Colors.white70 : Colors.white54,
                  fontWeight: FontWeight.normal,
                  fontSize: 14, // 减小字体大小
                ),
          ),
        ],
      ),
    );
  }
}

// 定义进度指示器组件，用于显示进度百分比
class _Indicator extends StatelessWidget {
  const _Indicator({required this.percent, required this.isLight});

  final double percent;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 70,
      // 进一步减小半径
      lineWidth: 8,
      // 减小线宽
      percent: percent,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisSize: MainAxisSize.min, // 限制高度为最小值
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${(percent * 100).toStringAsFixed(1)} %",
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(
                  fontSize: 16, // 减小完成度字体
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
                .useSystemChineseFont(),
          ),
          Text(
            "完成度",
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(
                  fontSize: 12, // 减小字体
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                )
                .useSystemChineseFont(),
          ),
        ],
      ),
      progressColor: Colors.white,
      backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
    );
  }
}
