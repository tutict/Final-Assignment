import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

/// 用户工具卡片组件
/// 此组件用于展示用户可使用的工具按钮，每个按钮代表一个功能
/// 按钮数量和功能根据传入的回调函数决定，最多支持六个功能按钮
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
  // 以下为可选的按钮回调函数，根据实际需要传入
  final Function()? onPressedSecond;
  final Function()? onPressedThird;
  final Function()? onPressedFourth;
  final Function()? onPressedFifth;
  final Function()? onPressedSixth;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 24.0),
            _buildButtonGrid(context),
          ],
        ),
      ),
    );
  }

  // 构建标题部分
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "用户工具",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
        'icon': EvaIcons.fileTextOutline
      },
      if (onPressedSecond != null)
        {
          'label': '罚款缴纳',
          'onPressed': onPressedSecond,
          'icon': EvaIcons.creditCardOutline
        },
      if (onPressedThird != null)
        {
          'label': '事故快处',
          'onPressed': onPressedThird,
          'icon': EvaIcons.carOutline
        },
      if (onPressedFourth != null)
        {
          'label': '事故处理进度',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.clockOutline
        },
      if (onPressedFifth != null)
        {
          'label': '事故证据材料',
          'onPressed': onPressedFifth,
          'icon': EvaIcons.archiveOutline
        },
      if (onPressedSixth != null)
        {
          'label': '事故视频快处',
          'onPressed': onPressedSixth,
          'icon': EvaIcons.videoOutline
        },
    ];

    return Wrap(
      spacing: 20.0, // 横向间距
      runSpacing: 20.0, // 纵向间距
      alignment: WrapAlignment.start,
      children: actions
          .map(
            (action) => _buildButton(
          context,
          onTap: action['onPressed'],
          text: action['label'],
          icon: action['icon'],
        ),
      )
          .toList(),
    );
  }

  // 构建按钮
  Widget _buildButton(BuildContext context,
      {required Function()? onTap,
        required String text,
        required IconData icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      splashColor: Theme.of(context).primaryColorLight.withOpacity(0.3),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(height: 12.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
