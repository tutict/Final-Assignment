import 'dart:ui';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';

class UserPredefinedQuestions extends StatelessWidget {
  final VoidCallback onQuestionTap; // 添加回调

  const UserPredefinedQuestions({super.key, required this.onQuestionTap});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final RxBool isExpanded = false.obs;

    final List<String> questions = [
      '如何查询我的交通违法记录？',
      '罚款缴纳的流程是什么？',
      '交通违法申诉需要哪些材料？',
      '我的罚款什么时候到期？',
      '如何处理超速违章？',
    ];

    final int halfLength = (questions.length / 2).ceil();
    final List<String> firstRow = questions.sublist(0, halfLength);
    final List<String> secondRow = questions.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Text(
                          '用户常见问题',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              )
                              .useSystemChineseFont(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Obx(() => Icon(
                            isExpanded.value
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          )),
                      onPressed: () => isExpanded.value = !isExpanded.value,
                      padding: const EdgeInsets.all(2.0),
                      constraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: isExpanded.value
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: firstRow
                              .map((question) => _buildButton(
                                  context, chatController, question))
                              .toList(),
                        ),
                        const SizedBox(height: 6.0),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: secondRow
                              .map((question) => _buildButton(
                                  context, chatController, question))
                              .toList(),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, ChatController chatController, String question) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: ElevatedButton(
        onPressed: () {
          chatController.textController.text = question;
          chatController.sendMessage();
          onQuestionTap(); // 点击时隐藏帮助小部件
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          minimumSize: const Size(0, 28),
        ),
        child: Text(
          question,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 10.0,
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
