import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

class ChatController extends GetxController {
  final messages = <ChatMessage>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatControllerApi chatApi = ChatControllerApi();

  Future<void> sendMessage() async {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(ChatMessage(message: text, isUser: true));
    textController.clear();
    scrollToBottom();

    try {
      final result = await chatApi.apiAiChatGet(text);
      if (result != null && result.isNotEmpty) {
        messages.add(ChatMessage(message: result, isUser: false)); // 直接显示纯文本
      } else {
        messages.add(ChatMessage(
            message: "AI did not return any message.", isUser: false));
      }
    } catch (e) {
      messages.add(ChatMessage(message: "错误: $e", isUser: false));
    }
    scrollToBottom();
  }

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

  void clearMessages() {
    messages.clear();
    textController.clear();
  }
}
