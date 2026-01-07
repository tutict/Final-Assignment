import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class FinePaymentNoticePage extends StatelessWidget {
  const FinePaymentNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '罚款缴纳须知',
      accentColor: Theme.of(context).colorScheme.primary,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '缴纳流程'),
          _buildStepCard(context, '1. 登录系统', '进入“罚款管理”模块，查看需缴纳的罚款。'),
          _buildStepCard(context, '2. 选择罚款记录', '核对罚款金额和扣分信息。'),
          _buildStepCard(context, '3. 支付确认', '支持线上支付，完成后自动更新状态。'),
          _buildSectionTitle(context, '温馨提示'),
          _buildContentCard(
            context,
            '及时缴纳',
            '逾期缴纳可能导致额外滞纳金或影响驾驶信用。',
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
