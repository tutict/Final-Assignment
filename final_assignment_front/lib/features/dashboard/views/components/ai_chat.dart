import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';
import 'package:get/get.dart';

class AiChat extends GetView<ChatController> {
  const AiChat({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建独立的 ScrollController，避免复用
    final ScrollController scrollController = ScrollController();

    // 在 dispose 时清理 ScrollController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(() {
        // 可选：监听滚动事件
      });
    });

    debugPrint(
        'AiChat constraints: ${BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3, minWidth: 150, maxHeight: MediaQuery.of(context).size.height)}');

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Obx(() {
            return ListView.builder(
              controller: scrollController, // 使用本地的 ScrollController
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    // 减小内边距
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12), // 减小圆角
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4, // 减小模糊半径
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: msg.isUser
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: SelectableText(
                      msg.message,
                      style: TextStyle(
                        fontFamily: 'SimsunExtG',
                        // 设置为宋体
                        fontSize: 14,
                        // 减小字体大小
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        // 减小行高
                        color: msg.isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.1, // 减小字间距
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // 预定义问题区域
        Obx(() => controller.userRole.value == "ADMIN"
            ? const ManagerPredefinedQuestions()
            : const UserPredefinedQuestions()),

        // 输入框和发送按钮
        Padding(
          padding: const EdgeInsets.all(4.0), // Reduced padding
          child: Row(
            mainAxisSize: MainAxisSize.min, // Restrict to minimum width
            children: [
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity, // Fills available space
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(
                      hintText: "请输入你的问题...",
                      hintStyle: TextStyle(
                        fontFamily: 'SimsunExtG',
                        fontSize: 15, // Smaller font size
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        // Smaller radius
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.0, // Thinner border
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, // Reduced padding
                        vertical: 4, // Reduced padding
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'SimsunExtG',
                      fontSize: 14, // Smaller font size
                      fontWeight: FontWeight.w400,
                      height: 1.0, // Reduced line height
                    ),
                    onSubmitted: (_) => controller.sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 2), // Reduced spacing
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(2),
                // Reduced padding
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                // Smaller size
                onPressed: controller.sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6), // Smaller radius
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
