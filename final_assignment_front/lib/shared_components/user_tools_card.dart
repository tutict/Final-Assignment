import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

/// 用户工具卡片组件
///
/// 此组件用于展示用户可使用的工具按钮，每个按钮代表一个功能。
/// 按钮数量和功能根据传入的回调函数决定，最多支持六个功能按钮。
class UserToolsCard extends StatelessWidget {
  const UserToolsCard({
    super.key,
    required this.onPressed,
    this.onPressedSecond,
    this.onPressedThird,
    this.onPressedFourth,
    this.onPressedFifth,
    this.onPressedSixth,
  });

  // 第一个按钮的回调函数，必传
  final Function()? onPressed;

  // 以下为可选的按钮回调函数
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
            const SizedBox(height: 24.0),
            // 可滚动的按钮网格
            Expanded(
              child: SingleChildScrollView(
                child: _buildButtonGrid(context),
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
        "用户工具",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  // 构建按钮网格
  Widget _buildButtonGrid(BuildContext context) {
    final actions = <Map<String, dynamic>>[
      {
        'label': '违法处理',
        'onPressed': onPressed,
        'icon': EvaIcons.fileTextOutline,
      },
      if (onPressedSecond != null)
        {
          'label': '罚款缴纳',
          'onPressed': onPressedSecond,
          'icon': EvaIcons.creditCardOutline,
        },
      if (onPressedThird != null)
        {
          'label': '事故快处',
          'onPressed': onPressedThird,
          'icon': EvaIcons.carOutline,
        },
      if (onPressedFourth != null)
        {
          'label': '事故处理进度',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.clockOutline,
        },
      if (onPressedFifth != null)
        {
          'label': '事故证据材料',
          'onPressed': onPressedFifth,
          'icon': EvaIcons.archiveOutline,
        },
      if (onPressedSixth != null)
        {
          'label': '事故视频快处',
          'onPressed': onPressedSixth,
          'icon': EvaIcons.videoOutline,
        },
    ];

    return Wrap(
      spacing: 20.0,
      runSpacing: 20.0,
      alignment: WrapAlignment.start,
      children: actions
          .map(
            (action) => _buildButton(
              context,
              onPressed: action['onPressed'],
              text: action['label'],
              icon: action['icon'],
            ),
          )
          .toList(),
    );
  }

  // 构建单个按钮组件
  Widget _buildButton(BuildContext context,
      {required Function()? onPressed,
      required String text,
      required IconData icon}) {
    return SizedBox(
      width: 110,
      height: 110,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
            const SizedBox(height: 12.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
