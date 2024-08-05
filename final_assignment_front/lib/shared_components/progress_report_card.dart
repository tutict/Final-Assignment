import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

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

class ProgressReportCard extends StatelessWidget {
  const ProgressReportCard({
    required this.data,
    super.key,
  });

  final ProgressReportCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(111, 88, 255, 1),
            Color.fromRGBO(157, 86, 248, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.title,
                style: const TextStyle(fontWeight: FontWeight.bold).useSystemChineseFont(),
              ),
              const SizedBox(height: 15),
              _RichText(value1: "${data.task} ", value2: "申诉"),
              const SizedBox(height: 3),
              _RichText(value1: "${data.doneTask} ", value2: "已处理的申诉"),
              const SizedBox(height: 3),
              _RichText(value1: "${data.undoneTask} ", value2: "未处理的申诉"),
            ],
          ),
          const Spacer(),
          _Indicator(percent: data.percent),
        ],
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  const _RichText({
    required this.value1,
    required this.value2,
  });

  final String value1;
  final String value2;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: kFontColorPallets[0],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        children: [
          TextSpan(text: value1),
          TextSpan(
            text: value2,
            style: TextStyle(
              color: kFontColorPallets[0],
              fontWeight: FontWeight.w100,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 140,
      lineWidth: 15,
      percent: percent,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${percent * 100} %",
            style: const TextStyle(fontWeight: FontWeight.bold).useSystemChineseFont(),
          ),
          Text(
            "完成度",
            style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 12).useSystemChineseFont(),
          ),
        ],
      ),
      progressColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(.3),
    );
  }
}
