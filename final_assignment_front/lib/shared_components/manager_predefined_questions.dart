import 'dart:ui'; // 用于 BackdropFilter
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:get/get.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      // 减小内边距
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // 减小阴影强度
            offset: const Offset(0, 1), // 减小偏移
            blurRadius: 4, // 减小模糊半径
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 减小模糊半径
          child: Container(
            padding: const EdgeInsets.all(6.0), // 减小内边距
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withOpacity(0.6), // 减小不透明度
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.1), // 减小边框不透明度
                width: 0.5, // 减小边框宽度
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 折叠按钮和标题，使用 Flexible 防止溢出
                Row(
                  mainAxisSize: MainAxisSize.min, // 限制宽度为最小值
                  children: [
                    Flexible(
                      // 限制文本宽度
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0), // 减小内边距
                        child: Text(
                          '管理员预定义问题',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14, // 进一步减小字体大小
                              )
                              .useSystemChineseFont(),
                          overflow: TextOverflow.ellipsis, // 文本溢出时省略
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
                            size: 20, // 进一步减小图标大小
                          )),
                      onPressed: () {
                        isExpanded.value = !isExpanded.value; // 切换折叠状态
                      },
                      padding: const EdgeInsets.all(2.0), // 进一步减少内边距
                      constraints: const BoxConstraints(
                        minWidth: 0, // 最小宽度为 0
                        minHeight: 0, // 最小高度为 0
                      ),
                    ),
                  ],
                ),
                // 问题列表，使用 Obx 监听折叠状态
                Obx(
                  () => AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200), // 减小动画持续时间
                    crossFadeState: isExpanded.value
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        // 第一行问题
                        Wrap(
                          spacing: 6.0, // 进一步减小间距
                          runSpacing: 6.0,
                          children: firstRow
                              .map((question) => _buildButton(
                                  context, chatController, question))
                              .toList(),
                        ),
                        const SizedBox(height: 6.0), // 进一步减小间距
                        // 第二行问题
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
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3, // 进一步减小宽度
      child: ElevatedButton(
        onPressed: () {
          chatController.textController.text = question;
          chatController.sendMessage();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
          // 减小不透明度
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          // 减小阴影
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // 进一步减小圆角
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          // 进一步减小内边距
          minimumSize: const Size(0, 28), // 进一步减小最小高度
        ),
        child: Text(
          question,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                // 使用更小的标签样式
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 10.0, // 进一步减小字体大小
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
