import 'package:final_assignment_front/features/api/chat_controller_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/model/chat_response.dart';

/// 聊天消息数据模型
class ChatMessage {
  final String message;
  final bool isUser; // true 表示用户发送，false 表示 AI 回复

  ChatMessage({required this.message, required this.isUser});
}

/// 聊天控制器，管理消息列表、文本输入和滚动
class ChatController extends GetxController {
  // 消息列表（使用 RxList 监听变化）
  final messages = <ChatMessage>[].obs;

  // 文本输入控制器
  final TextEditingController textController = TextEditingController();

  // 滚动控制器
  final ScrollController scrollController = ScrollController();

  /// 发送消息并调用 API 获取 AI 回复
  Future<void> sendMessage() async {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    messages.add(ChatMessage(message: text, isUser: true));
    textController.clear();
    scrollToBottom();

    try {
      // 调用 API 获取 AI 回复（这里调用 GET 接口，可根据实际接口修改）
      final result = await ChatControllerApi().apiAiChatGet();
      // 假设返回的是 ChatResponse 对象
      if (result is ChatResponse && result.message != null) {
        messages
            .add(ChatMessage(message: "AI: ${result.message}", isUser: false));
      } else {
        messages.add(ChatMessage(
            message: "AI did not return any message.", isUser: false));
      }
    } catch (e) {
      messages.add(ChatMessage(message: "Error: $e", isUser: false));
    }
    scrollToBottom();
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

  /// 清空消息列表和输入框
  void clearMessages() {
    messages.clear();
    textController.clear();
  }
}
