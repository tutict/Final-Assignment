import 'dart:ui';
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
  final RxBool isSearchResultsExpanded = false.obs;
  late Animation<Offset> _searchSlideAnimation;

  @override
  void initState() {
    super.initState();
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

    return Column(
      children: [
// Fixed Top Component: Search Results
        Obx(() => Visibility(
              visible: controller.searchResults.isNotEmpty,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.hardEdge, // Ensure scrollbar is clipped
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: isSearchResultsExpanded.value ? 150 : 48,
                    // Collapsed: title height, Expanded: 150px
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
// Fixed Title
                        GestureDetector(
                          onTap: toggleSearchResults,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '搜索结果',
                                  style: TextStyle(
                                    fontFamily: 'SimsunExtG',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
// Scrollable Content with Venetian Blind Animation
                        Obx(() => isSearchResultsExpanded.value
                            ? SlideTransition(
                                position: _searchSlideAnimation,
                                child: SizedBox(
                                  height:
                                      102, // Content area: 150px - 48px title
                                  child: ScrollConfiguration(
                                    behavior: const ScrollBehavior()
                                        .copyWith(scrollbars: true),
                                    child: RawScrollbar(
                                      thumbColor:
                                          Theme.of(context).colorScheme.primary,
                                      thickness: 4,
                                      radius: const Radius.circular(2),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: controller.searchResults
                                              .map((result) => ListTile(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16,
                                                            vertical: 0),
                                                    title: SelectableText(
                                                      result,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'SimsunExtG',
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
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
                ),
              ),
            )),

// Scrollable content: Messages
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            // Remove scrollbars
            child: CustomScrollView(
              slivers: [
// Message List
                SliverFillRemaining(
                  child: Obx(() {
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
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
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.2),
                                  width: 0.5,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '思考中...',
                                    style: TextStyle(
                                      fontFamily: 'SimsunExtG',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.2,
                                      color: Colors.grey[400],
                                      letterSpacing: 0.1,
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
                                vertical: 8, horizontal: 12),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
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
                          curve: Curves.easeInOut,
                        )),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
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
                Obx(() => Container(
                      constraints: const BoxConstraints(maxHeight: 220),
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
                Row(
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
                    Obx(() => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: controller.webSearchEnabled.value
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: controller.webSearchEnabled.value
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.wifi,
                              size: 20,
                              color: controller.webSearchEnabled.value
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.all(8),
                            onPressed: () {
                              controller.toggleWebSearch(
                                  !controller.webSearchEnabled.value);
                            },
                            tooltip: '联网搜索',
                            highlightColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            splashRadius: 20,
                          ),
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
