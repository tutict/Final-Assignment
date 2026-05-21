import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class LatestOffenseNewsPage extends StatelessWidget {
  const LatestOffenseNewsPage({super.key});

  static const _accentColor = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '最新交通违法新闻',
      subtitle: '聚合近期治理动态、规则调整和安全提醒。',
      badge: '3 条动态',
      icon: Icons.article_outlined,
      accentColor: _accentColor,
      contentBuilder: (context, theme) => const _LatestOffenseNewsContent(),
    );
  }
}

class _LatestOffenseNewsContent extends StatelessWidget {
  const _LatestOffenseNewsContent();

  static const _accentColor = LatestOffenseNewsPage._accentColor;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NewsSummaryPanel(
          title: '交通违法治理动态',
          description: '按发布时间整理新规、专项整治和智能监管信息，帮助驾驶员快速了解近期变化。',
          icon: Icons.campaign_outlined,
          accentColor: _accentColor,
          chips: ['交规更新', '专项整治', '智能监管'],
        ),
        NewsSectionTitle(
          title: '头条新闻',
          subtitle: '优先关注影响面较大的规则变化',
        ),
        NewsFeaturedArticle(
          title: '2025 年新交规实施',
          description: '超速、闯红灯、酒驾等高风险违法行为的处理要求进一步细化，系统将同步展示处罚依据和办理入口。',
          meta: '2025-02-27',
          icon: Icons.gavel_rounded,
          accentColor: _accentColor,
        ),
        NewsSectionTitle(
          title: '近期动态',
          subtitle: '持续更新与办理流程相关的信息',
        ),
        NewsInfoTile(
          title: '酒驾专项整治启动',
          description: '多地开展夜间重点路段抽查，驾驶员可在违法详情中查看检测时间、地点和处理状态。',
          meta: '2025-02-25',
          icon: Icons.local_police_outlined,
          accentColor: _accentColor,
        ),
        NewsInfoTile(
          title: '智能监控设备升级',
          description: '新增设备覆盖主干道路和重点路口，违法记录会同步关联抓拍图片、地点和审核状态。',
          meta: '2025-02-20',
          icon: Icons.videocam_outlined,
          accentColor: _accentColor,
        ),
        NewsSectionTitle(
          title: '办理建议',
          subtitle: '减少重复提交和线下往返',
        ),
        NewsInfoTile(
          title: '及时核对违法记录',
          description: '收到违法提醒后先核对车辆、驾驶人和发生时间，确认无误后再进入处理或申诉流程。',
          icon: Icons.fact_check_outlined,
          accentColor: _accentColor,
        ),
      ],
    );
  }
}
