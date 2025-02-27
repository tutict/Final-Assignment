import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';

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
                      color: msg.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      msg.message,
                      style: TextStyle(
                        color: msg.isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        // 根据角色切换预定义问题框
        Obx(() => controller.userRole.value == "ADMIN"
            ? const ManagerPredefinedQuestions()
            : const UserPredefinedQuestions()),
        // 输入区域
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 100, maxWidth: 300),
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(
                      hintText: "请输入你的问题...",
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
        ),
      ],
    );
  }
}
