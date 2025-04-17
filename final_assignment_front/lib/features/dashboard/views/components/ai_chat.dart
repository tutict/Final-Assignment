import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';
import 'package:get/get.dart';

class AiChat extends GetView<ChatController> {
  const AiChat({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    // 动画控制器
    final AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    );
    // 显示状态
    final RxBool showHelperWidget = true.obs;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(() {});
    });

    // 定义隐藏帮助小部件的函数
    void hideHelperWidget() {
      animationController.forward().then((_) {
        showHelperWidget.value = false;
        animationController.reset();
      });
    }

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Obx(() {
            return ListView.builder(
              controller: scrollController,
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
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: msg.isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // 帮助小部件 - 修改为向右滑动消失
        Obx(() => showHelperWidget.value
            ? SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero, // 起始位置
                  end: const Offset(1, 0), // 结束位置，向右滑动 (x: 1, y: 0)
                ).animate(CurvedAnimation(
                  parent: animationController,
                  curve: Curves.easeInOut,
                )),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          child: const Image(
                            image: AssetImage(ImageRasterPath.logo4),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '有问题可以问问DeepSeek',
                        style: TextStyle(
                          fontFamily: 'SimsunExtG',
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink()),
        // 预定义问题区域，传递隐藏函数
        Obx(() => controller.userRole.value == "ADMIN"
            ? ManagerPredefinedQuestions(onQuestionTap: hideHelperWidget)
            : UserPredefinedQuestions(onQuestionTap: hideHelperWidget)),

        // 输入框和发送按钮
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(
                      hintText: "请输入你的问题...",
                      hintStyle: TextStyle(
                        fontFamily: 'SimsunExtG',
                        fontSize: 15,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                          width: 1.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'SimsunExtG',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                    onSubmitted: (_) {
                      controller.sendMessage();
                      hideHelperWidget();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: () {
                  controller.sendMessage();
                  hideHelperWidget();
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
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
