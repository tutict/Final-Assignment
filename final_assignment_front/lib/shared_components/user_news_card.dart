import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

/// 用户新闻卡片组件
///
/// 此组件用于展示用户相关的新闻小卡片，每个卡片代表一条新闻。
/// 卡片数量和内容根据传入的回调函数决定，最多支持六个新闻条目。
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

  // 第一个新闻的回调函数，必传
  final Function()? onPressed;

  // 以下为可选的新闻回调函数
  final Function()? onPressedSecond;
  final Function()? onPressedThird;
  final Function()? onPressedFourth;
  final Function()? onPressedFifth;
  final Function()? onPressedSixth;

  @override
  Widget build(BuildContext context) {
    final Color cardBackgroundColor = Theme.of(context).cardColor;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.all(16.0),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 固定顶部标题和分隔线
            _buildHeader(context),
            const Divider(
              thickness: 2,
              indent: 16,
              endIndent: 16,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16.0),
            // 可滚动的新闻卡片列表
            Expanded(
              child: SingleChildScrollView(
                child: _buildNewsList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建标题部分
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "用户指南",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  // 构建新闻卡片列表
  Widget _buildNewsList(BuildContext context) {
    final newsItems = <Map<String, dynamic>>[
      {
        'title': '最新交通违法新闻',
        'description': '了解最新的交通违法处理动态',
        'onPressed': onPressed,
        'icon': EvaIcons.fileTextOutline,
      },
      if (onPressedSecond != null)
        {
          'title': '罚款缴纳须知',
          'description': '查看罚款缴纳的最新通知',
          'onPressed': onPressedSecond,
          'icon': EvaIcons.creditCardOutline,
        },
      if (onPressedThird != null)
        {
          'title': '事故快处指南',
          'description': '快速处理交通事故的步骤',
          'onPressed': onPressedThird,
          'icon': EvaIcons.carOutline,
        },
      if (onPressedFourth != null)
        {
          'title': '事故处理进度介绍',
          'description': '了解如何跟踪事故处理状态',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.clockOutline,
        },
      if (onPressedFifth != null)
        {
          'title': '事故证据材料',
          'description': '查看事故相关证据要求',
          'onPressed': onPressedFifth,
          'icon': EvaIcons.archiveOutline,
        },
      if (onPressedSixth != null)
        {
          'title': '事故视频快处',
          'description': '了解利用拍摄视频快速处理事故的流程',
          'onPressed': onPressedSixth,
          'icon': EvaIcons.videoOutline,
        },
    ];

    return Column(
      children: newsItems
          .map(
            (item) => _buildNewsItem(
              context,
              onPressed: item['onPressed'],
              title: item['title'],
              description: item['description'],
              icon: item['icon'],
            ),
          )
          .toList(),
    );
  }

  // 构建单个新闻卡片
  Widget _buildNewsItem(BuildContext context,
      {required Function()? onPressed,
      required String title,
      required String description,
      required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
