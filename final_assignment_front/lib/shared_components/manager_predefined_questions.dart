import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:get/get.dart';

class ManagerPredefinedQuestions extends StatelessWidget {
  final VoidCallback onQuestionTap; // 添加回调

  const ManagerPredefinedQuestions({super.key, required this.onQuestionTap});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final RxBool isExpanded = false.obs;

    final List<String> adminQuestions = [
      '如何查看所有未处理的交通违法记录？',
      '如何统计本月罚款缴纳总额？',
      '有哪些待审核的交通违法申诉？',
      '如何批量更新罚款到期状态？',
      '超速违章的处理流程是什么？',
    ];

    final int halfLength = (adminQuestions.length / 2).ceil();
    final List<String> firstRow = adminQuestions.sublist(0, halfLength);
    final List<String> secondRow = adminQuestions.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
                          '管理员预定义问题',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              )
                              ,
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
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
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
