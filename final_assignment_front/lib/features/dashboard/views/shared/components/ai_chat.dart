import 'package:final_assignment_front/features/dashboard/bindings/chat_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final ScrollController scrollController = ScrollController();
  final RxBool showPromptPanel = true.obs;
  final RxBool searchResultsExpanded = false.obs;

  @override
  void initState() {
    super.initState();
    AiChatBinding.registerDependencies();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void hidePromptPanel() {
    showPromptPanel.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.94 : 0.98),
      ),
      child: Column(
        children: [
          _SearchResultsStrip(
            controller: controller,
            expanded: searchResultsExpanded,
          ),
          Expanded(
            child: Obx(
              () => controller.messages.isEmpty
                  ? _AssistantEmptyState(
                      accentColor: scheme.primary,
                    )
                  : _MessageList(
                      controller: controller,
                      scrollController: scrollController,
                    ),
            ),
          ),
          _ComposerSurface(
            controller: controller,
            showPromptPanel: showPromptPanel,
            onPromptTap: hidePromptPanel,
          ),
        ],
      ),
    );
  }
}

class _SearchResultsStrip extends StatelessWidget {
  const _SearchResultsStrip({
    required this.controller,
    required this.expanded,
  });

  final ChatController controller;
  final RxBool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (controller.searchResults.isEmpty) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: dark ? 0.52 : 0.74,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.38 : 0.56),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => expanded.value = !expanded.value,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Icon(
                      Icons.travel_explore_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '联网搜索结果',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Obx(
                      () => Icon(
                        expanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: expanded.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 138),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: controller.searchResults.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 12,
                      color: scheme.outlineVariant.withValues(alpha: 0.34),
                    ),
                    itemBuilder: (context, index) => SelectableText(
                      controller.searchResults[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.scrollController,
  });

  final ChatController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final msg = controller.messages[index];
            if (msg.formalContent.startsWith('THINKING:')) {
              return _ThinkingBubble(maxWidth: constraints.maxWidth * 0.86);
            }
            return _MessageBubble(
              message: msg,
              maxWidth: constraints.maxWidth * 0.88,
            );
          },
        );
      },
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: dark ? 0.42 : 0.78,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.38 : 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '思考中...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.maxWidth,
  });

  final ChatMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;
    final isSystem = message.isSystem;
    final bubbleColor = isUser
        ? scheme.primary
        : isSystem
            ? scheme.tertiaryContainer.withValues(alpha: dark ? 0.46 : 0.82)
            : scheme.surfaceContainerHighest.withValues(
                alpha: dark ? 0.48 : 0.78,
              );
    final foregroundColor = isUser
        ? scheme.onPrimary
        : isSystem
            ? scheme.onTertiaryContainer
            : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isUser ? 8 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 8),
          ),
          border: Border.all(
            color: isUser
                ? scheme.primary.withValues(alpha: 0.62)
                : scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.thinkContent.isNotEmpty)
              SelectableText(
                message.thinkContent,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.72),
                  height: 1.36,
                  letterSpacing: 0,
                ),
              ),
            if (message.thinkContent.isNotEmpty &&
                message.formalContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: foregroundColor.withValues(alpha: 0.24),
                ),
              ),
            if (message.formalContent.isNotEmpty)
              SelectableText(
                message.formalContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor.withValues(alpha: isUser ? 0.96 : 0.9),
                  height: 1.42,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({
    required this.accentColor,
  });

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: dark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: accentColor,
              size: 27,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '交通业务智能助手',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可以帮你梳理违法查询、罚款缴纳、申诉材料和事故快处流程。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.42,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CapabilityChip(label: '违法查询', icon: Icons.fact_check_outlined),
              _CapabilityChip(label: '罚款缴纳', icon: Icons.payments_outlined),
              _CapabilityChip(label: '申诉指引', icon: Icons.gavel_outlined),
              _CapabilityChip(label: '事故快处', icon: Icons.car_crash_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.38 : 0.76,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.52),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerSurface extends StatelessWidget {
  const _ComposerSurface({
    required this.controller,
    required this.showPromptPanel,
    required this.onPromptTap,
  });

  final ChatController controller;
  final RxBool showPromptPanel;
  final VoidCallback onPromptTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: dark ? 0.98 : 0.99),
          border: Border(
            top: BorderSide(
              color:
                  scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.55),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: showPromptPanel.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: controller.userRole.value == 'ADMIN'
                      ? ManagerPredefinedQuestions(onQuestionTap: onPromptTap)
                      : UserPredefinedQuestions(onQuestionTap: onPromptTap),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '输入问题，按 Enter 发送',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                        letterSpacing: 0,
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(
                        alpha: dark ? 0.34 : 0.70,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.50),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.50),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.78),
                          width: 1.4,
                        ),
                      ),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.36,
                      letterSpacing: 0,
                    ),
                    onSubmitted: (_) {
                      controller.sendMessage();
                      onPromptTap();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => _ComposerIconButton(
                    selected: controller.webSearchEnabled.value,
                    icon: Icons.travel_explore_rounded,
                    tooltip: '联网搜索',
                    onPressed: () {
                      controller.toggleWebSearch(
                        !controller.webSearchEnabled.value,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => _ComposerIconButton(
                    selected: true,
                    filled: true,
                    icon: controller.isStreaming.value
                        ? Icons.stop_rounded
                        : Icons.send_rounded,
                    tooltip: controller.isStreaming.value ? '停止生成' : '发送',
                    onPressed: () {
                      if (controller.isStreaming.value) {
                        controller.stopStreaming();
                      } else {
                        controller.sendMessage();
                        onPromptTap();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = filled
        ? scheme.primary
        : selected
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.56);
    final foregroundColor = filled
        ? scheme.onPrimary
        : selected
            ? scheme.primary
            : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: foregroundColor, size: 20),
          ),
        ),
      ),
    );
  }
}
