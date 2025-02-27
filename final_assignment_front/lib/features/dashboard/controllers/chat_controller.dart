import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

class ChatController extends GetxController {
  static ChatController get to => Get.find(); // 添加静态 getter 确保单例

  final messages = <ChatMessage>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatControllerApi chatApi = ChatControllerApi();

  // 用户角色状态，默认值为 "USER"
  final RxString userRole = "USER".obs;

  // 设置用户角色的方法
  void setUserRole(String role) {
    userRole.value = role.toUpperCase();
    print('ChatController: User role set to $role'); // 添加调试日志
  }

  Future<void> sendMessage() async {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(ChatMessage(message: text, isUser: true));
    textController.clear();
    scrollToBottom();

    try {
      final result = await chatApi.apiAiChatGet(text);
      if (result != null && result.isNotEmpty) {
        messages.add(ChatMessage(message: "AI: $result", isUser: false));
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
