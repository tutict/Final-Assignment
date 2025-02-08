import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// AI 聊天对话界面组件
class AiChat extends GetView<ChatController> {
  const AiChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Obx(() {
            return ListView.builder(
              controller: controller.scrollController,
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          msg.isUser ? Colors.blueAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        // 输入区域
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.textController,
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => controller.sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: controller.sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
