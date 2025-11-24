import 'package:final_assignment_front/features/dashboard/views/user_screens/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentQuickGuidePage extends StatelessWidget {
  const AccidentQuickGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '事故快处指南',
      accentColor: Colors.teal,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '快速处理步骤'),
          _buildStepCard(context, '1. 确保安全', '将车辆移至安全位置，打开警示灯。'),
          _buildStepCard(context, '2. 拍照取证', '拍摄事故现场照片，至少三张不同角度。'),
          _buildStepCard(context, '3. 在线提交', '通过系统上传照片并填写事故详情。'),
          _buildSectionTitle(context, '注意事项'),
          _buildStepCard(context, '4. 时间限制', '需在事故发生后24小时内提交。'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String title,
    String content,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Text(
            title.split('.')[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
