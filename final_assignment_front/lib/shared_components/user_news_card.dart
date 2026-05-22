import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// 驾驶员主页用户指南面板。
class UserNewsCard extends StatelessWidget {
  const UserNewsCard({
    super.key,
    required this.onPressed,
    this.onPressedSecond,
    this.onPressedThird,
    this.onPressedFourth,
    this.onPressedFifth,
    this.onPressedSixth,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onPressedSecond;
  final VoidCallback? onPressedThird;
  final VoidCallback? onPressedFourth;
  final VoidCallback? onPressedFifth;
  final VoidCallback? onPressedSixth;

  @override
  Widget build(BuildContext context) {
    final items = _guideItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final featured = items.first;
        final secondaryItems = items.skip(1).toList();

        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideHeader(total: items.length),
              const SizedBox(height: 14),
              _FeaturedGuideItem(
                item: featured,
                onPressed: featured.onPressed,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: isWide
                      ? _TwoColumnGuideGrid(items: secondaryItems)
                      : _GuideList(items: secondaryItems),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_GuideItemData> get _guideItems => [
        _GuideItemData(
          title: '最新交通违法新闻',
          description: '了解最新交通违法治理、处罚调整和办事动态。',
          category: '政策动态',
          actionText: '查看新闻',
          icon: EvaIcons.fileTextOutline,
          accent: const Color(0xFF2F80ED),
          onPressed: onPressed,
        ),
        if (onPressedSecond != null)
          _GuideItemData(
            title: '罚款缴纳须知',
            description: '确认缴款入口、支付状态和票据处理方式。',
            category: '缴费',
            actionText: '查看须知',
            icon: EvaIcons.creditCardOutline,
            accent: const Color(0xFF25A7A0),
            onPressed: onPressedSecond,
          ),
        if (onPressedThird != null)
          _GuideItemData(
            title: '事故快处指南',
            description: '按步骤完成现场确认、材料提交和快速处理。',
            category: '事故',
            actionText: '进入指南',
            icon: EvaIcons.carOutline,
            accent: const Color(0xFFE5A33A),
            onPressed: onPressedThird,
          ),
        if (onPressedFourth != null)
          _GuideItemData(
            title: '事故处理进度',
            description: '了解处理状态含义，掌握后续跟进节点。',
            category: '进度',
            actionText: '查看进度',
            icon: EvaIcons.clockOutline,
            accent: const Color(0xFF7C8CF8),
            onPressed: onPressedFourth,
          ),
        if (onPressedFifth != null)
          _GuideItemData(
            title: '事故证据材料',
            description: '核对照片、视频和证明材料的提交要求。',
            category: '材料',
            actionText: '查看材料',
            icon: EvaIcons.archiveOutline,
            accent: const Color(0xFFB16CEA),
            onPressed: onPressedFifth,
          ),
        if (onPressedSixth != null)
          _GuideItemData(
            title: '事故视频快处',
            description: '通过视频记录快速完成事故信息核验。',
            category: '视频',
            actionText: '了解流程',
            icon: EvaIcons.videoOutline,
            accent: const Color(0xFFEF6C5B),
            onPressed: onPressedSixth,
          ),
      ];
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.34 : 0.56,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              EvaIcons.bookOpenOutline,
              color: scheme.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用户指南',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '集中查看违法新闻、缴款须知和事故处理指引。',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: dark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$total 项',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedGuideItem extends StatelessWidget {
  const _FeaturedGuideItem({
    required this.item,
    required this.onPressed,
  });

  final _GuideItemData item;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.surface,
              item.accent,
              dark ? 0.10 : 0.055,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item.accent.withValues(alpha: dark ? 0.42 : 0.32),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final iconBox = Container(
                width: compact ? 46 : 52,
                height: compact ? 46 : 52,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: dark ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.accent, size: 26),
              );
              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: item.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: scheme.outlineVariant.withValues(
                            alpha: dark ? 0.32 : 0.42,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: compact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              );
              final actionBadge = _GuideActionBadge(
                label: item.actionText,
                accent: item.accent,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        iconBox,
                        const SizedBox(width: 12),
                        Expanded(child: textBlock),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionBadge,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  iconBox,
                  const SizedBox(width: 14),
                  Expanded(child: textBlock),
                  const SizedBox(width: 12),
                  actionBadge,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TwoColumnGuideGrid extends StatelessWidget {
  const _TwoColumnGuideGrid({required this.items});

  final List<_GuideItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _GuideTile(item: items[index])),
                const SizedBox(width: 10),
                Expanded(
                  child: index + 1 < items.length
                      ? _GuideTile(item: items[index + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.items});

  final List<_GuideItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GuideTile(item: item),
          ),
      ],
    );
  }
}

class _GuideTile extends StatefulWidget {
  const _GuideTile({required this.item});

  final _GuideItemData item;

  @override
  State<_GuideTile> createState() => _GuideTileState();
}

class _GuideTileState extends State<_GuideTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final item = widget.item;
    final borderColor = _hovered
        ? item.accent.withValues(alpha: dark ? 0.62 : 0.46)
        : scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.48);
    final backgroundColor = _hovered
        ? Color.lerp(scheme.surface, item.accent, dark ? 0.08 : 0.045)
        : scheme.surface.withValues(alpha: dark ? 0.72 : 0.94);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(13),
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.accent, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: item.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Text(
                            item.actionText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: item.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: item.accent,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideActionBadge extends StatelessWidget {
  const _GuideActionBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward_rounded, color: accent, size: 16),
        ],
      ),
    );
  }
}

class _GuideItemData {
  const _GuideItemData({
    required this.title,
    required this.description,
    required this.category,
    required this.actionText,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String category;
  final String actionText;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
}
