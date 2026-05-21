import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class FinePaymentNoticePage extends StatelessWidget {
  const FinePaymentNoticePage({super.key});

  static const _accentColor = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '罚款缴纳须知',
      subtitle: '核对记录、完成支付并留存凭证。',
      badge: '3 步',
      icon: Icons.credit_card_rounded,
      accentColor: _accentColor,
      contentBuilder: (context, theme) => const _FinePaymentNoticeContent(),
    );
  }
}

class _FinePaymentNoticeContent extends StatelessWidget {
  const _FinePaymentNoticeContent();

  static const _accentColor = FinePaymentNoticePage._accentColor;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NewsSummaryPanel(
          title: '罚款缴纳流程',
          description: '缴款前先确认违法记录和处罚金额，支付完成后等待系统同步回写处理状态。',
          icon: Icons.receipt_long_outlined,
          accentColor: _accentColor,
          chips: ['记录核验', '在线支付', '状态回写'],
        ),
        NewsSectionTitle(
          title: '缴纳步骤',
          subtitle: '按顺序完成，避免重复支付',
        ),
        NewsTimelineItem(
          index: 1,
          title: '进入罚款缴纳',
          description: '在业务办理中打开罚款缴纳，系统会列出当前账号关联的待缴记录。',
          accentColor: _accentColor,
        ),
        NewsTimelineItem(
          index: 2,
          title: '核对处罚信息',
          description: '确认车牌号、违法时间、金额和扣分信息，信息不一致时先发起申诉。',
          accentColor: _accentColor,
        ),
        NewsTimelineItem(
          index: 3,
          title: '完成支付确认',
          description: '支付成功后保留电子凭证，系统一般会在短时间内更新为已处理状态。',
          accentColor: _accentColor,
          isLast: true,
        ),
        NewsSectionTitle(
          title: '缴款提醒',
          subtitle: '影响状态同步和后续业务办理',
        ),
        NewsInfoTile(
          title: '避免逾期缴纳',
          description: '逾期可能产生滞纳金，并影响车辆年检、驾驶证业务和信用记录。',
          meta: '重点',
          icon: Icons.event_busy_outlined,
          accentColor: _accentColor,
        ),
        NewsInfoTile(
          title: '不要重复支付',
          description: '支付后如果页面未立即刷新，请先点击刷新或稍后查询，不要连续提交付款。',
          icon: Icons.sync_problem_outlined,
          accentColor: _accentColor,
        ),
      ],
    );
  }
}
