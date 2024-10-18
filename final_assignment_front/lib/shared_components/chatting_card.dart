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
  const ChattingCard({required this.data, required this.onPressed, super.key});

  final ChattingCardData data;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: kSpacing),
          leading: Stack(
            children: [
              CircleAvatar(backgroundImage: data.image),
              CircleAvatar(
                backgroundColor: data.isOnline ? Colors.green : Colors.grey,
                radius: 5,
              ),
            ],
          ),
          title: Text(
            data.name,
            style: TextStyle(
              fontSize: 13,
              color: kFontColorPallets[0],
            ).useSystemChineseFont(),
          ),
          subtitle: Text(
            data.lastMessage,
            style: TextStyle(
              fontSize: 11,
              color: kFontColorPallets[2],
            ),
          ),
          onTap: onPressed,
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
