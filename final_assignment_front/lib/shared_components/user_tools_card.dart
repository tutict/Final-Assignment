import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

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

  final Function()? onPressed;
  final Function()? onPressedSecond;
  final Function()? onPressedThird;
  final Function()? onPressedFourth;
  final Function()? onPressedFifth;
  final Function()? onPressedSixth;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 16.0),
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 构建按钮网格
  Widget _buildButtonGrid(BuildContext context) {
    final actions = <Map<String, dynamic>>[
      {'label': '违法处理', 'onPressed': onPressed, 'icon': EvaIcons.arrowForward},
      if (onPressedSecond != null)
        {
          'label': '罚款缴纳',
          'onPressed': onPressedSecond,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedThird != null)
        {
          'label': '事故快处',
          'onPressed': onPressedThird,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedFourth != null)
        {
          'label': '事故处理进度',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedFifth != null)
        {
          'label': '事故证据材料',
          'onPressed': onPressedFifth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedSixth != null)
        {
          'label': '事故视频快处',
          'onPressed': onPressedSixth,
          'icon': EvaIcons.arrowForwardOutline
        },
    ];

    return Wrap(
      spacing: 16.0, // 横向间距
      runSpacing: 16.0, // 纵向间距
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
      borderRadius: BorderRadius.circular(12.0),
      splashColor: Theme.of(context).primaryColorLight.withOpacity(0.2),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(height: 8.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
