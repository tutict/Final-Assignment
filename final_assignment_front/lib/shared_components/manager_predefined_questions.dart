import 'dart:ui'; // 用于 BackdropFilter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';

/// AI 预制问题选项栏组件
/// 展示两层与交通违法相关的预定义问题，用户点击后发送到 AI 聊天界面，支持折叠
class ManagerPredefinedQuestions extends StatelessWidget {
  const ManagerPredefinedQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

    // 使用 GetX 的 RxBool 控制折叠状态，默认折叠
    final RxBool isExpanded = false.obs;

    // 交通违法相关的预定义问题列表
    final List<String> adminQuestions = [
      '如何查看所有未处理的交通违法记录？',
      '如何统计本月罚款缴纳总额？',
      '有哪些待审核的交通违法申诉？',
      '如何批量更新罚款到期状态？',
      '超速违章的处理流程是什么？',
    ];

    // 将问题分为两行
    final int halfLength = (adminQuestions.length / 2).ceil();
    final List<String> firstRow = adminQuestions.sublist(0, halfLength);
    final List<String> secondRow = adminQuestions.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 磨砂效果
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withOpacity(0.7), // 半透明背景
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 折叠按钮和标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '管理员预定义问题',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Obx(() => Icon(
                            isExpanded.value
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          )),
                      onPressed: () {
                        isExpanded.value = !isExpanded.value; // 切换折叠状态
                      },
                    ),
                  ],
                ),
                // 问题列表，使用 Obx 监听折叠状态
                Obx(
                  () => AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isExpanded.value
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        // 第一行问题
                        Wrap(
                          spacing: 10.0, // 增加间距
                          runSpacing: 10.0,
                          children: firstRow
                              .map((question) => _buildButton(
                                  context, chatController, question))
                              .toList(),
                        ),
                        const SizedBox(height: 10.0),
                        // 第二行问题
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: secondRow
                              .map((question) => _buildButton(
                                  context, chatController, question))
                              .toList(),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(), // 折叠时隐藏
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建单个按钮
  Widget _buildButton(
      BuildContext context, ChatController chatController, String question) {
    return ElevatedButton(
      onPressed: () {
        chatController.textController.text = question;
        chatController.sendMessage();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 3,
        // 增加阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // 更大圆角
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        minimumSize: const Size(0, 40), // 设置最小高度
      ),
      child: Text(
        question,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
