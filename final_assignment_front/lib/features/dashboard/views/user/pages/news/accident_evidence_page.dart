import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentEvidencePage extends StatelessWidget {
  const AccidentEvidencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '事故证据材料',
      accentColor: Colors.orangeAccent,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '必备证据'),
          _buildContentCard(
            context,
            '照片资料',
            '需要提供事故现场、车辆损坏、路面状况的多角度照片。',
          ),
          _buildContentCard(
            context,
            '视频资料',
            '如有行车记录仪视频或监控视频，可大幅提升处理效率。',
          ),
          _buildContentCard(
            context,
            '事故详情',
            '包括事故时间、地点、天气情况以及双方驾驶员信息。',
          ),
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

  Widget _buildContentCard(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
