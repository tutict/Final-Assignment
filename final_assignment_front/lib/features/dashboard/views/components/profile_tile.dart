import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:flutter/material.dart';

class ProfilTile extends StatelessWidget {
  const ProfilTile(
      {super.key, required this.data, required this.onPressedNotification});

  final Profile data;
  final VoidCallback onPressedNotification;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color backgroundColor =
        isLight ? Colors.white : Theme.of(context).cardColor.withOpacity(0.9);
    final Color shadowColor = Colors.black.withOpacity(isLight ? 0.1 : 0.2);
    final Color defaultTextColor = isLight
        ? Colors.black87 // 亮色模式下使用深灰色，确保可见
        : Colors.white;
    final Color subtitleTextColor = isLight
        ? Colors.grey.shade600 // 亮色模式下使用较深的灰色
        : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // 添加圆角
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        // 增加垂直内边距以适应更大文本
        leading: GestureDetector(
          onTap: () {
            // 头像点击逻辑（可选：导航到个人详情）
            debugPrint("Avatar clicked");
          },
          child: CircleAvatar(
            backgroundImage: data.photo,
            radius: 24, // 保持头像大小
            backgroundColor:
                isLight ? Colors.grey.shade200 : Colors.grey.shade800,
          ),
        ),
        title: Text(
          data.name,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(
                fontSize: 18, // 增大字体到 18
                fontWeight: FontWeight.w600, // 保持加粗
                color: defaultTextColor, // 使用调整后的颜色
              )
              .useSystemChineseFont(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          data.email,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(
                fontSize: 16, // 增大字体到 16
                color: subtitleTextColor, // 使用调整后的颜色
                fontWeight: FontWeight.w400,
              )
              .useSystemChineseFont(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: onPressedNotification,
          icon: Icon(
            EvaIcons.bellOutline,
            size: 24, // 保持图标大小
            color: isLight ? Colors.grey.shade700 : Colors.white70,
          ),
          tooltip: "通知",
          splashRadius: 24,
          // 保持涟漪效果范围
          splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
          // 保持点击反馈
          highlightColor: Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 保持圆角一致
        ),
      ),
    );
  }
}
