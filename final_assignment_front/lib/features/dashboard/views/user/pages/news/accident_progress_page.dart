import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentProgressPage extends StatelessWidget {
  const AccidentProgressPage({super.key});

  static const _accent = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step('登录系统', '使用您的账号登录交通违法处理管理系统，进入用户仪表板。'),
      _Step('进入事故管理', '在仪表板中选择“事故管理”选项，查看所有已提交的事故记录。'),
      _Step('查看进度详情', '点击具体事故编号，查看当前状态（如“已提交”、“审核中”或“已完成”）。'),
    ];

    return NewsPageLayout(
      title: '事故处理状态追踪',
      subtitle: '跟踪事故处理进度',
      accentColor: _accent,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NewsSectionTitle(title: '如何跟踪事故处理状态'),
          for (var i = 0; i < steps.length; i++)
            NewsTimelineItem(
              index: i + 1,
              title: steps[i].title,
              description: steps[i].description,
              accentColor: _accent,
              isLast: i == steps.length - 1,
            ),
          const NewsSectionTitle(title: '实用建议'),
          const NewsInfoTile(
            title: '定期检查',
            description: '建议每周登录系统检查事故处理进度，确保及时响应审核要求。',
            icon: Icons.event_repeat_outlined,
            accentColor: _accent,
          ),
          const NewsInfoTile(
            title: '通知设置',
            description: '启用系统通知，获取状态更新的实时提醒，避免遗漏重要信息。',
            icon: Icons.notifications_active_outlined,
            accentColor: _accent,
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step(this.title, this.description);

  final String title;
  final String description;
}
