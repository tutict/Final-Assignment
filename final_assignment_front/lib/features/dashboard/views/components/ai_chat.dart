import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';
import 'package:get/get.dart';

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  _AiChatState createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  final ScrollController scrollController = ScrollController();
  final RxBool showHelperWidget = true.obs;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(() {});
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void hideHelperWidget() {
    animationController.forward().then((_) {
      showHelperWidget.value = false;
      animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();

    return Column(
      children: [
// Search Results
        Obx(() => Visibility(
              visible: controller.searchResults.isNotEmpty,
              child: ExpansionTile(
                title: Text(
                  '搜索结果',
                  style: TextStyle(
                    fontFamily: 'SimsunExtG',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: controller.searchResults
                    .map((result) => ListTile(
                          title: SelectableText(
                            result,
                            style: TextStyle(
                              fontFamily: 'SimsunExtG',
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            )),

// Message List
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
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.thinkContent.isNotEmpty)
                          SelectableText(
                            msg.thinkContent,
                            style: TextStyle(
                              fontFamily: 'SimsunExtG',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                              color: Colors.grey[400],
                              letterSpacing: 0.1,
                            ),
                          ),
                        if (msg.thinkContent.isNotEmpty &&
                            msg.formalContent.isNotEmpty)
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            height: 8,
                          ),
                        if (msg.formalContent.isNotEmpty)
                          SelectableText(
                            msg.formalContent,
                            style: TextStyle(
                              fontFamily: 'SimsunExtG',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                              color: msg.isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),

// Helper Widget
        Obx(() => showHelperWidget.value
            ? SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(1, 0),
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

// Predefined Questions
        Obx(() => controller.userRole.value == "ADMIN"
            ? ManagerPredefinedQuestions(onQuestionTap: hideHelperWidget)
            : UserPredefinedQuestions(onQuestionTap: hideHelperWidget)),

// Input, Web Search, and Send Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.textController,
                  decoration: InputDecoration(
                    hintText: "请输入你的问题...",
                    hintStyle: TextStyle(
                      fontFamily: 'SimsunExtG',
                      fontSize: 14,
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'SimsunExtG',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  onSubmitted: (_) {
                    controller.sendMessage();
                    hideHelperWidget();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => IconButton(
                    icon: Icon(
                      Icons.wifi,
                      size: 20,
                      color: controller.webSearchEnabled.value
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      controller
                          .toggleWebSearch(!controller.webSearchEnabled.value);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: '联网搜索',
                  )),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, size: 20),
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(8),
                onPressed: () {
                  controller.sendMessage();
                  hideHelperWidget();
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
