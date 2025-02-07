import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 聊天消息数据模型
class ChatMessage {
  final String message;
  final bool isUser; // true 表示用户发送，false 表示 AI 回复
  ChatMessage({required this.message, required this.isUser});
}

/// 聊天控制器，管理消息列表、文本输入和滚动
class ChatController extends GetxController {
  // 消息列表
  var messages = <ChatMessage>[].obs;

  // 文本输入控制器
  final TextEditingController textController = TextEditingController();

  // 滚动控制器
  final ScrollController scrollController = ScrollController();

  /// 发送消息并模拟 AI 回复
  void sendMessage() {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    messages.add(ChatMessage(message: text, isUser: true));
    textController.clear();
    scrollToBottom();

    // 模拟 AI 回复（1 秒后）
    Future.delayed(const Duration(seconds: 1), () {
      messages.add(ChatMessage(message: "AI: I received \"$text\".", isUser: false));
      scrollToBottom();
    });
  }

  /// 滚动到消息列表底部
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
