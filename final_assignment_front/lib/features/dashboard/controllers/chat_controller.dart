import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

class ChatController extends GetxController {
  static ChatController get to => Get.find();

  final messages = <ChatMessage>[].obs;
  final TextEditingController textController = TextEditingController();
  final ChatControllerApi chatApi = ChatControllerApi();

  final RxString userRole = "USER".obs;

  void setUserRole(String role) {
    userRole.value = role.toUpperCase();
    debugPrint('ChatController: User role set to $role');
  }

  Future<void> sendMessage() async {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    messages.add(ChatMessage(message: text, isUser: true));
    debugPrint('添加用户消息: $text');
    textController.clear();

    try {
      // 添加初始 AI 消息
      messages.add(ChatMessage(message: "DeepSeek: ", isUser: false));
      int aiMessageIndex = messages.length - 1; // 记录 AI 消息的索引
      StringBuffer currentMessage = StringBuffer();

      await for (String chunk in chatApi.apiAiChatStream(text)) {
        String cleanChunk = chatApi.removeMarkdown(chunk); // 移除标签

        // 将片段拆分为字符并逐个显示
        for (int i = 0; i < cleanChunk.length; i++) {
          currentMessage.write(cleanChunk[i]);
          // 更新最后一条 AI 消息，而不是添加新消息
          messages[aiMessageIndex] = ChatMessage(
            message: "DeepSeek: ${currentMessage.toString()}",
            isUser: false,
          );
          await Future.delayed(const Duration(milliseconds: 50)); // 每个字符延迟 50ms
        }
      }

      debugPrint('AI 流完成: $text');
    } catch (e) {
      debugPrint('流式 AI 响应错误: $e');
      messages.add(ChatMessage(message: "错误: $e", isUser: false));
    }
  }

  void clearMessages() {
    messages.clear();
    textController.clear();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
