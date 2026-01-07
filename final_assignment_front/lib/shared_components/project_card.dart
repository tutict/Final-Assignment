// 导入所需包和库
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/Get.dart';
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
class ProjectCard extends StatefulWidget {
  const ProjectCard({
    required this.data,
    super.key,
  });

  final ProjectCardData data;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 每秒更新时间
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 清理定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProgressIndicator(
          percent: widget.data.percent,
          center: _ProfilImage(image: widget.data.projectImage),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleText(widget.data.projectName),
              const SizedBox(height: 8),
              Row(
                children: [
                  const _SubtitleText("现在时间: "),
                  _ReleaseTimeText(_currentTime), // 使用当前时间
                ],
              ),
            ],
          ),
        ),
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color progressColor = isLight ? Theme.of(context).primaryColor : Colors.blueAccent;
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color textColor = isLight ? Colors.black87 : Colors.white;
    return Text(
      data.capitalize!,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.0,
      ),
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color textColor = isLight ? Colors.black54 : Colors.white70;
    return Text(
      data,
      style: TextStyle(
        fontSize: 12,
        color: textColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 项目发布时间文本组件，展示当前时间
class _ReleaseTimeText extends StatelessWidget {
  const _ReleaseTimeText(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
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
        DateFormat('HH:mm:ss').format(date), // 改为显示时:分:秒
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