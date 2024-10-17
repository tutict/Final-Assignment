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
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildHeader(),
          _buildButtonGrid(context),
        ],
      ),
    );
  }

  // 构建标题部分
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 8.0),
        ],
      ),
    );
  }

  // 构建按钮网格
  Widget _buildButtonGrid(BuildContext context) {
    final actions = <Map<String, dynamic>>[
      {
        'label': '违法处理',
        'onPressed': onPressed,
        'icon': EvaIcons.arrowForward
      },
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
          'label': '事故处理进度和结果',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedFifth != null)
        {
          'label': '事故证据材料查阅',
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
      spacing: 8.0, // 横向间距
      runSpacing: 8.0, // 纵向间距
      alignment: WrapAlignment.center,
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
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.lightBlueAccent, size: 20),
            const SizedBox(height: 4.0, width: 4.0),
            Text(
              text,
              style: const TextStyle(color: Colors.black, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
