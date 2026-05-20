import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/bindings/chat_binding.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/shared_components/user_predefined_questions.dart';
import 'package:final_assignment_front/shared_components/manager_predefined_questions.dart';
import 'package:get/get.dart';

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  final ScrollController scrollController = ScrollController();
  final RxBool showHelperWidget = true.obs;
  final RxBool isSearchResultsExpanded = false.obs;
  late Animation<Offset> _searchSlideAnimation;

  @override
  void initState() {
    super.initState();
    AiChatBinding.registerDependencies();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide animation for search results (venetian blind effect)
    _searchSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

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

  void toggleSearchResults() {
    isSearchResultsExpanded.value = !isSearchResultsExpanded.value;
    if (isSearchResultsExpanded.value) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          // Fixed Top Component: Search Results
          Obx(() => Visibility(
                visible: controller.searchResults.isNotEmpty,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: isSearchResultsExpanded.value ? 160 : 48,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: toggleSearchResults,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '搜索结果',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.9),
                                  letterSpacing: 0,
                                ),
                              ),
                              Obx(() => Icon(
                                    isSearchResultsExpanded.value
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      Obx(() => isSearchResultsExpanded.value
                          ? SlideTransition(
                              position: _searchSlideAnimation,
                              child: SizedBox(
                                height: 112,
                                child: ScrollConfiguration(
                                  behavior: const ScrollBehavior()
                                      .copyWith(scrollbars: true),
                                  child: RawScrollbar(
                                    thumbColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.7),
                                    thickness: 3,
                                    radius: const Radius.circular(2),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: controller.searchResults
                                            .map((result) => ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 12,
                                                    vertical: 2,
                                                  ),
                                                  title: SelectableText(
                                                    result,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                              alpha: 0.85),
                                                      letterSpacing: 0,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              )),

          // Scrollable content: Messages
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Obx(() {
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = controller.messages[index];
                          if (msg.formalContent.startsWith('THINKING:')) {
                            // Render "Thinking..." message with animation
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.65,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.2),
                                    width: 1,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '思考中...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Message rendering
                          return Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.65,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: msg.isSystem
                                      ? [
                                          Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withValues(alpha: 0.85),
                                          Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.85),
                                        ]
                                      : msg.isUser
                                          ? [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.9),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.7),
                                            ]
                                          : [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainer
                                                  .withValues(alpha: 0.9),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainer
                                                  .withValues(alpha: 0.7),
                                            ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: msg.isSystem
                                      ? Theme.of(context)
                                          .colorScheme
                                          .tertiary
                                          .withValues(alpha: 0.45)
                                      : msg.isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3)
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg.thinkContent.isNotEmpty)
                                    SelectableText(
                                      msg.thinkContent,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  if (msg.thinkContent.isNotEmpty &&
                                      msg.formalContent.isNotEmpty)
                                    Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.5),
                                      height: 12,
                                      thickness: 1,
                                    ),
                                  if (msg.formalContent.isNotEmpty)
                                    SelectableText(
                                      msg.formalContent,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                        color: msg.isSystem
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer
                                                .withValues(alpha: 0.9)
                                            : msg.isUser
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withValues(alpha: 0.9)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.85),
                                        letterSpacing: 0,
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
                ],
              ),
            ),
          ),

          // Fixed Bottom Components: Helper Widget, Predefined Questions, Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Helper Widget
                  Obx(() => showHelperWidget.value
                      ? SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset.zero,
                            end: const Offset(1, 0),
                          ).animate(CurvedAnimation(
                            parent: animationController,
                            curve: Curves.easeInOutCubic,
                          )),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
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
                                        .withValues(alpha: 0.3),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.9),
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),

                  // Predefined Questions
                  Obx(() => Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SingleChildScrollView(
                          child: controller.userRole.value == "ADMIN"
                              ? ManagerPredefinedQuestions(
                                  onQuestionTap: hideHelperWidget)
                              : UserPredefinedQuestions(
                                  onQuestionTap: hideHelperWidget),
                        ),
                      )),

                  // Search Bar
                  ClipRect(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.textController,
                            decoration: InputDecoration(
                              hintText: "请输入你的问题...",
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                letterSpacing: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.85),
                              letterSpacing: 0,
                            ),
                            onSubmitted: (_) {
                              controller.sendMessage();
                              hideHelperWidget();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Obx(() => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: controller.webSearchEnabled.value
                                      ? [
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.2),
                                        ]
                                      : [
                                          Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.2),
                                          Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.1),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: controller.webSearchEnabled.value
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.8)
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.wifi,
                                  size: 18,
                                  color: controller.webSearchEnabled.value
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.9)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                ),
                                padding: const EdgeInsets.all(6),
                                onPressed: () {
                                  controller.toggleWebSearch(
                                      !controller.webSearchEnabled.value);
                                },
                                tooltip: '联网搜索',
                                highlightColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                splashRadius: 18,
                              ),
                            )),
                        const SizedBox(width: 6),
                        Obx(() => IconButton(
                              icon: Icon(
                                controller.isStreaming.value
                                    ? Icons.stop
                                    : Icons.send,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.9),
                              ),
                              padding: const EdgeInsets.all(6),
                              onPressed: () {
                                if (controller.isStreaming.value) {
                                  controller.stopStreaming();
                                } else {
                                  controller.sendMessage();
                                  hideHelperWidget();
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.1),
                              ),
                              tooltip: '发送',
                              highlightColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              splashRadius: 18,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
