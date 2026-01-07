import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class LatestTrafficViolationNewsPage extends StatelessWidget {
  const LatestTrafficViolationNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '最新交通违法新闻',
      accentColor: Colors.blueAccent,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '头条新闻'),
          _buildNewsCard(
            context,
            '2025年新交规实施',
            '自2025年1月1日起，超速10%以上将面临更高罚款和扣分，旨在提升道路安全。',
            '2025-02-27',
          ),
          _buildSectionTitle(context, '近期动态'),
          _buildNewsCard(
            context,
            '酒驾专项整治启动',
            '全国范围内开展为期三个月的酒驾整治行动，已查处3000余起违法行为。',
            '2025-02-25',
          ),
          _buildNewsCard(
            context,
            '智能监控升级',
            '新增1000个智能摄像头，覆盖主要城市，自动识别闯红灯和超速行为。',
            '2025-02-20',
          ),
          _buildSectionTitle(context, '专家建议'),
          _buildContentCard(
            context,
            '遵守交通法规',
            '专家呼吁司机严格遵守新规，避免不必要的罚款和安全隐患。',
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
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    String title,
    String description,
    String date,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 4,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
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
