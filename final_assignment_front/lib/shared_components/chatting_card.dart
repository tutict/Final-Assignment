import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// 用户聊天卡片数据类
/// 包含用户的头像、在线状态、姓名、最后一条消息、消息是否已读以及未读消息总数
class ChattingCardData {
  final ImageProvider image;
  final bool isOnline;
  final String name;
  final String lastMessage;
  final bool isRead;
  final int totalUnread;

  const ChattingCardData({
    required this.image,
    required this.isOnline,
    required this.name,
    required this.lastMessage,
    required this.isRead,
    required this.totalUnread,
  });
}

/// 用户聊天卡片组件
/// 根据传入的数据展示用户的聊天信息，并在用户点击时执行相应操作
class ChattingCard extends StatelessWidget {
  const ChattingCard({
    required this.data,
    required this.onPressed,
    super.key,
  });

  final ChattingCardData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          // 水平内边距保持不变
          contentPadding: const EdgeInsets.symmetric(horizontal: kSpacing),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              // 用户头像
              CircleAvatar(backgroundImage: data.image),
              // 在线状态小圆点（使用 Positioned 定位到头像的右下角）
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.isOnline ? Colors.green : Colors.grey,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          // 用户名
          title: Text(
            data.name,
            style: TextStyle(
              fontSize: 13,
              color: kFontColorPallets[0],
            )
            // 解决中文字体兼容
                .useSystemChineseFont(),
            // 避免姓名过长导致的溢出
            overflow: TextOverflow.ellipsis,
          ),
          // 最后一条消息
          subtitle: Text(
            data.lastMessage,
            style: TextStyle(
              fontSize: 11,
              color: kFontColorPallets[2],
            ),
            // 同样做溢出省略处理
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onPressed,
          // 右侧：未读消息 or 已读状态
          trailing: (!data.isRead && data.totalUnread > 1)
              ? _notif(data.totalUnread)
              : Icon(
            Icons.check,
            color: data.isRead ? Colors.grey : Colors.green,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // 底部分割线
        const Divider(),
      ],
    );
  }

  /// 未读消息通知 widget
  /// 当未读消息数量超过1时显示
  Widget _notif(int total) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).primaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        (total >= 100) ? "99+" : "$total",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
