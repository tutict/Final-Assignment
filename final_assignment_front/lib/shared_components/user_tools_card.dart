import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class UserToolsCard extends StatelessWidget {
  const UserToolsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.onPressedSecond,
    this.onPressedThird,
    this.onPressedFourth,
    this.onPressedFifth,
    this.onPressedSixth,
    this.onPressedSeventh,
    this.onPressedEighth,
    this.onPressedNinth,
    this.onPressedTenth,
  });

  final String title;
  final IconData icon;
  final Function() onPressed;
  final Function()? onPressedSecond;
  final Function()? onPressedThird;
  final Function()? onPressedFourth;
  final Function()? onPressedFifth;
  final Function()? onPressedSixth;
  final Function()? onPressedSeventh;
  final Function()? onPressedEighth;
  final Function()? onPressedNinth;
  final Function()? onPressedTenth;

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 48.0,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 8.0),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 构建按钮网格
  Widget _buildButtonGrid(BuildContext context) {
    final actions = <Map<String, dynamic>>[
      {
        'label': 'Primary Action',
        'onPressed': onPressed,
        'icon': EvaIcons.arrowForward
      },
      if (onPressedSecond != null)
        {
          'label': 'Second Action',
          'onPressed': onPressedSecond,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedThird != null)
        {
          'label': 'Third Action',
          'onPressed': onPressedThird,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedFourth != null)
        {
          'label': 'Fourth Action',
          'onPressed': onPressedFourth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedFifth != null)
        {
          'label': 'Fifth Action',
          'onPressed': onPressedFifth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedSixth != null)
        {
          'label': 'Sixth Action',
          'onPressed': onPressedSixth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedSeventh != null)
        {
          'label': 'Seventh Action',
          'onPressed': onPressedSeventh,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedEighth != null)
        {
          'label': 'Eighth Action',
          'onPressed': onPressedEighth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedNinth != null)
        {
          'label': 'Ninth Action',
          'onPressed': onPressedNinth,
          'icon': EvaIcons.arrowForwardOutline
        },
      if (onPressedTenth != null)
        {
          'label': 'Tenth Action',
          'onPressed': onPressedTenth,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.lightBlueAccent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.lightBlueAccent, size: 16),
            const SizedBox(width: 4.0),
            Text(
              text,
              style: const TextStyle(color: Colors.lightBlueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
