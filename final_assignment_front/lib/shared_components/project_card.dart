// 导入所需包和库
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// 定义项目卡片数据模型，包含项目图片、名称、发布时间和完成百分比
class ProjectCardData {
  final double percent;
  final ImageProvider projectImage;
  final String projectName;
  final DateTime releaseTime;

  const ProjectCardData({
    required this.projectImage,
    required this.projectName,
    required this.releaseTime,
    required this.percent,
  });
}

/// 项目卡片组件，用于展示单个项目的信息
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.data,
    super.key,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    // 项目卡片布局，包括进度指示器、项目图片、项目名称和发布时间
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProgressIndicator(
          percent: data.percent,
          center: _ProfilImage(image: data.projectImage),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleText(data.projectName),
              const SizedBox(height: 8),
              Row(
                children: [
                  const _SubtitleText("更新时间: "),
                  _ReleaseTimeText(data.releaseTime)
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

/* -----------------------------> COMPONENTS <------------------------------ */

/// 自定义进度指示器组件，展示项目的完成百分比
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.percent,
    required this.center,
  });

  final double percent;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    // 根据当前主题判断亮暗
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    // 在亮色模式下使用当前主题的 primaryColor；暗色模式下可使用蓝色强调
    final Color progressColor =
        isLight ? Theme.of(context).primaryColor : Colors.blueAccent;
    return CircularPercentIndicator(
      radius: 45,
      lineWidth: 4.0,
      percent: percent,
      center: center,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.grey.shade300,
      progressColor: progressColor,
    );
  }
}

/// 项目图片组件，展示项目图标或图片
class _ProfilImage extends StatelessWidget {
  const _ProfilImage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    // 根据当前主题判断亮暗，调整背景颜色
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return ClipOval(
      child: Container(
        width: 40,
        height: 40,
        color: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
        child: Image(
          image: image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// 项目名称文本组件，展示项目名称
class _TitleText extends StatelessWidget {
  const _TitleText(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    // 根据当前主题设置文本颜色
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color textColor = isLight ? Colors.black87 : Colors.white;
    return Text(
      data.capitalize!,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.0,
      ).useSystemChineseFont(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 项目副标题文本组件，用于展示项目更新时间等信息
class _SubtitleText extends StatelessWidget {
  const _SubtitleText(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    // 根据当前主题设置副标题文本颜色
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color textColor = isLight ? Colors.black54 : Colors.white70;
    return Text(
      data,
      style: TextStyle(
        fontSize: 12,
        color: textColor,
      ).useSystemChineseFont(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 项目发布时间文本组件，展示项目发布时间
class _ReleaseTimeText extends StatelessWidget {
  const _ReleaseTimeText(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // 根据当前主题设置背景色（这里保留原来的 kNotifColor，但可调整透明度）
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color bgColor = isLight
        ? kNotifColor.withAlpha((0.8 * 255).toInt())
        : kNotifColor.withAlpha((0.6 * 255).toInt());
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        DateFormat.yMMMd('zh_CN').format(date),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
