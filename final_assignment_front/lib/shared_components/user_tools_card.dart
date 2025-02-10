import 'dart:ui';
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
    // 根据当前主题判断是否为亮色模式
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    // 卡片背景：亮色模式下为纯白，暗色模式下为深灰色
    final Color cardBackgroundColor =
        isLight ? Colors.white : Colors.grey[850]!;
    // 标题文本颜色：亮色模式下使用深色；暗色模式下使用浅色
    final Color headerTextColor = isLight ? Colors.black87 : Colors.white70;

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.all(16.0),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // 使用 SingleChildScrollView 防止内容超出时溢出
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 根据内容高度自适应
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(headerTextColor),
              const Divider(
                thickness: 2,
                indent: 16,
                endIndent: 16,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24.0),
              _buildButtonGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  // 构建标题部分
  Widget _buildHeader(Color headerTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "用户工具",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: headerTextColor,
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

  // 构建单个按钮组件
  Widget _buildButton(BuildContext context,
      {required Function()? onTap,
      required String text,
      required IconData icon}) {
    // 获取当前主题亮度判断是否为亮色模式
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    // 调整按钮背景颜色：亮色模式下使用较高不透明度的白色背景；暗色模式下使用深色背景
    final Color buttonBackground = isLight
        ? Colors.white.withOpacity(0.4)
        : Colors.grey[800]!.withOpacity(0.4);
    // 阴影颜色
    final Color shadowColor = isLight ? Colors.black12 : Colors.black26;
    // 按钮内图标颜色：在亮色模式下使用当前主题的 primaryColor；在暗色模式下采用蓝色强调
    final Color iconColor =
        isLight ? Theme.of(context).primaryColor : Colors.blueAccent;
    // 按钮标签文本颜色：亮色模式下使用深色；暗色模式下使用白色
    final Color textColor = isLight ? Colors.black87 : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      splashColor: Theme.of(context).primaryColorLight.withOpacity(0.3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: buttonBackground,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(height: 12.0),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
