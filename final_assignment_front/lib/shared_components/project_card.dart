// 导入所需包和库
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

// 定义项目卡片数据模型，包含项目图片、名称、发布时间和完成百分比
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

// 项目卡片组件，用于展示单个项目的信息
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleText(data.projectName),
              const SizedBox(height: 5),
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

// 自定义进度指示器组件，展示项目的完成百分比
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.percent,
    required this.center,
  });

  final double percent;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    // 使用CircularPercentIndicator展示百分比进度，配置外观和颜色
    return CircularPercentIndicator(
      radius: 55,
      lineWidth: 2.0,
      percent: percent,
      center: center,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.blueGrey,
      progressColor: Theme.of(Get.context!).primaryColor,
    );
  }
}

// 项目图片组件，展示项目图标或图片
class _ProfilImage extends StatelessWidget {
  const _ProfilImage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    // 使用CircleAvatar展示圆形项目图片，并设置图片来源和背景色
    return CircleAvatar(
      backgroundImage: image,
      radius: 20,
      backgroundColor: Colors.white,
    );
  }
}

// 项目名称文本组件，展示项目名称
class _TitleText extends StatelessWidget {
  const _TitleText(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    // 使用Text组件展示项目名称，配置字体、颜色和对齐方式
    return Text(
      data.capitalize!,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kFontColorPallets[0],
        letterSpacing: 0.8,
      ).useSystemChineseFont(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// 项目副标题文本组件，用于展示项目更新时间等信息
class _SubtitleText extends StatelessWidget {
  const _SubtitleText(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    // 使用Text组件展示项目副标题信息，配置字体和颜色
    return Text(
      data,
      style: TextStyle(fontSize: 11, color: kFontColorPallets[2])
          .useSystemChineseFont(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// 项目发布时间文本组件，展示项目发布时间
class _ReleaseTimeText extends StatelessWidget {
  const _ReleaseTimeText(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // 使用Container组件包裹Text，展示项目发布时间，配置背景色和文本样式
    return Container(
      decoration: BoxDecoration(
        color: kNotifColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      child: Text(
        DateFormat.yMMMd('zh_CN').format(date),
        style: const TextStyle(fontSize: 9, color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
