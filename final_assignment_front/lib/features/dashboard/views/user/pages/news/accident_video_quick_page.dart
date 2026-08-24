import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentVideoQuickPage extends StatelessWidget {
  const AccidentVideoQuickPage({super.key});

  static const _accent = Colors.green;

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step('录制视频', '拍摄事故现场视频，时长不超过1分钟。'),
      _Step('上传视频', '通过系统上传视频文件，支持MP4格式。'),
      _Step('提交审核', '填写事故详情并提交，等待处理结果。'),
    ];

    return NewsPageLayout(
      title: '事故视频快处',
      subtitle: '视频快速处理流程',
      accentColor: _accent,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NewsSummaryPanel(
            title: '视频快处流程',
            description: '通过视频快速处理事故，减少现场等待时间。',
            icon: Icons.videocam_outlined,
            accentColor: _accent,
            chips: ['≤1分钟', 'MP4', '24小时审核'],
          ),
          for (var i = 0; i < steps.length; i++)
            NewsTimelineItem(
              index: i + 1,
              title: steps[i].title,
              description: steps[i].description,
              accentColor: _accent,
              isLast: i == steps.length - 1,
            ),
          const NewsSectionTitle(title: '优势'),
          const NewsFeaturedArticle(
            title: '快速高效',
            description: '视频快处可减少现场等待时间，最快24小时内完成审核。',
            meta: '快速',
            icon: Icons.bolt_outlined,
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
