import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentQuickGuidePage extends StatelessWidget {
  const AccidentQuickGuidePage({super.key});

  static const _accentColor = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '事故快处指南',
      subtitle: '轻微事故按步骤完成现场取证与在线提交。',
      badge: '24 小时内',
      icon: Icons.directions_car_filled_rounded,
      accentColor: _accentColor,
      contentBuilder: (context, theme) => const _AccidentQuickGuideContent(),
    );
  }
}

class _AccidentQuickGuideContent extends StatelessWidget {
  const _AccidentQuickGuideContent();

  static const _accentColor = AccidentQuickGuidePage._accentColor;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NewsSummaryPanel(
          title: '轻微事故线上快处',
          description: '适用于人员无伤亡、车辆可移动、责任清晰的轻微事故，先确保安全再提交材料。',
          icon: Icons.verified_user_outlined,
          accentColor: _accentColor,
          chips: ['现场安全', '拍照取证', '线上提交'],
        ),
        NewsSectionTitle(
          title: '快处步骤',
          subtitle: '按步骤操作，保留关键证据',
        ),
        NewsTimelineItem(
          index: 1,
          title: '确认人员安全',
          description: '开启危险报警灯，在确保安全的前提下将车辆移至不影响通行的位置。',
          accentColor: _accentColor,
        ),
        NewsTimelineItem(
          index: 2,
          title: '拍摄现场照片',
          description: '至少保留全景、碰撞部位、车牌和道路标线等照片，角度要清晰完整。',
          accentColor: _accentColor,
        ),
        NewsTimelineItem(
          index: 3,
          title: '填写事故信息',
          description: '录入事故时间、地点、当事人和车辆信息，并上传现场照片。',
          accentColor: _accentColor,
        ),
        NewsTimelineItem(
          index: 4,
          title: '提交等待确认',
          description: '提交后关注进度消息，必要时按系统提示补充材料或转线下处理。',
          accentColor: _accentColor,
          isLast: true,
        ),
        NewsSectionTitle(
          title: '不适用场景',
          subtitle: '以下情况应及时报警或线下处理',
        ),
        NewsInfoTile(
          title: '存在人员伤亡或重大损失',
          description: '涉及人员伤亡、酒驾嫌疑、车辆无法移动或责任争议明显时，不建议线上快处。',
          meta: '报警',
          icon: Icons.warning_amber_rounded,
          accentColor: _accentColor,
        ),
      ],
    );
  }
}
