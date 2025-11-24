import 'package:final_assignment_front/features/dashboard/views/user_screens/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentProgressPage extends StatelessWidget {
  const AccidentProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '事故处理状态追踪',
      accentColor: Colors.deepPurple,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '如何跟踪事故处理状态'),
          _buildStepCard(
            context,
            '1. 登录系统',
            '使用您的账号登录交通违法处理管理系统，进入用户仪表板。',
          ),
          _buildStepCard(
            context,
            '2. 进入事故管理',
            '在仪表板中选择“事故管理”选项，查看所有已提交的事故记录。',
          ),
          _buildStepCard(
            context,
            '3. 查看进度详情',
            '点击具体事故编号，查看当前状态（如“已提交”、“审核中”或“已完成”）。',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(context, '实用建议'),
          _buildContentCard(
            context,
            '定期检查',
            '建议每周登录系统检查事故处理进度，确保及时响应审核要求。',
          ),
          _buildContentCard(
            context,
            '通知设置',
            '启用系统通知，获取状态更新的实时提醒，避免遗漏重要信息。',
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
