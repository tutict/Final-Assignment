import 'dart:async';

import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/ai/ai_chat_api.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatMessage {
  const ChatMessage({
    this.thinkContent = '',
    this.formalContent = '',
    required this.isUser,
    this.isSystem = false,
  });

  final String thinkContent;
  final String formalContent;
  final bool isUser;
  final bool isSystem;
}

enum ChatLoadingState { idle, thinking, searching, generating }

class ChatController extends GetxController {
  static ChatController get to => Get.find();

  final messages = <ChatMessage>[].obs;
  final searchResults = <String>[].obs;
  final TextEditingController textController = TextEditingController();
  final ChatControllerApi chatApi = ChatControllerApi();

  final RxString userRole = 'USER'.obs;
  final RxBool enableWordStreaming = true.obs;
  final RxInt wordStreamDelayMs = 150.obs;
  final RxBool webSearchEnabled = false.obs;
  final RxBool isStreaming = false.obs;
  final Rx<ChatLoadingState> loadingState = ChatLoadingState.idle.obs;

  CancelToken? _activeCancelToken;
  StreamSubscription<ChatStreamChunk>? _activeStreamSubscription;
  String? _sessionKey;
  bool _contextLimitHintShown = false;

  String get loadingText {
    return switch (loadingState.value) {
      ChatLoadingState.idle => '',
      ChatLoadingState.thinking => '思考中...',
      ChatLoadingState.searching => '正在搜索相关信息...',
      ChatLoadingState.generating => '生成中...',
    };
  }

  void setUserRole(String role) {
    userRole.value = role.toUpperCase();
    AppLogger.debug('ChatController: User role set to $role');
  }

  void toggleWebSearch(bool enable) {
    webSearchEnabled.value = enable;
    AppLogger.debug('Web search enabled: $enable');
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isStreaming.value) return;

    final conversationWindow = _buildConversationWindow();
    if (messages.length >= 20) {
      _showContextLimitHint();
    }

    messages.add(ChatMessage(formalContent: text, isUser: true));
    loadingState.value = webSearchEnabled.value
        ? ChatLoadingState.searching
        : ChatLoadingState.thinking;
    messages.add(ChatMessage(
      formalContent: webSearchEnabled.value
          ? 'THINKING: Searching...'
          : 'THINKING: Thinking...',
      isUser: false,
    ));
    textController.clear();

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;
    isStreaming.value = true;

    var aiMessageIndex = messages.length - 1;
    final thinkBuffer = StringBuffer();
    final formalBuffer = StringBuffer();
    final chunkBuffer = StringBuffer();
    final processedChunks = <String>{};
    Timer? debounceTimer;
    var isFirstMessage = true;
    var receivedFallback = false;
    var receivedAiContent = false;

    Future<void> processChunk(ChatStreamChunk streamChunk) async {
      if (cancelToken.isCanceled) return;

      if (_sessionKey == null && streamChunk.sessionKey != null) {
        _sessionKey = streamChunk.sessionKey;
      }

      final chunk = streamChunk.text;
      if (streamChunk.isFallback) {
        receivedFallback = true;
        _removeThinkingMessage();
        messages.add(ChatMessage(
          formalContent: chunk,
          isUser: false,
          isSystem: true,
        ));
        AppLogger.debug(
          'AI fallback shown as system message: ${streamChunk.fallbackReason ?? 'unknown'}',
        );
        return;
      }

      loadingState.value = ChatLoadingState.generating;

      if (processedChunks.contains(chunk)) {
        AppLogger.debug('Skipping duplicate chunk: $chunk');
        return;
      }
      processedChunks.add(chunk);

      if (chunk.startsWith('[SEARCH]') && webSearchEnabled.value) {
        final result = chunk.substring('[SEARCH]'.length).trim();
        if (result.isNotEmpty) {
          searchResults.add(result);
        }
        return;
      }

      if (isFirstMessage) {
        _removeThinkingMessage();
        messages
            .add(const ChatMessage(formalContent: 'DeepSeek: ', isUser: false));
        aiMessageIndex = messages.length - 1;
        isFirstMessage = false;
      }

      receivedAiContent = true;
      chunkBuffer.write(chunk);

      if (chunkBuffer.length <= 100 && (debounceTimer?.isActive ?? false)) {
        return;
      }

      final cleanChunk = chunkBuffer.toString();
      chunkBuffer.clear();
      await _appendAiText(
        cleanChunk,
        aiMessageIndex,
        thinkBuffer,
        formalBuffer,
        debounceTimer,
      );
      if (!enableWordStreaming.value) {
        debounceTimer = Timer(const Duration(milliseconds: 100), () {
          _updateAiMessage(aiMessageIndex, thinkBuffer, formalBuffer);
        });
      }
    }

    try {
      final streamDone = Completer<void>();
      late final StreamSubscription<ChatStreamChunk> subscription;
      subscription = chatApi
          .streamChatChunks(
        text,
        webSearchEnabled.value,
        sessionKey: _sessionKey,
        metadata: {
          'conversationWindow': conversationWindow,
        },
        cancelToken: cancelToken,
      )
          .listen(
        (chunk) {
          subscription.pause();
          unawaited(() async {
            try {
              await processChunk(chunk);
            } catch (error, stackTrace) {
              if (!streamDone.isCompleted) {
                streamDone.completeError(error, stackTrace);
              }
              await subscription.cancel();
              return;
            }
            if (!streamDone.isCompleted && !cancelToken.isCanceled) {
              subscription.resume();
            }
          }());
        },
        onError: (Object error, StackTrace stackTrace) {
          if (cancelToken.isCanceled) {
            if (!streamDone.isCompleted) streamDone.complete();
            return;
          }
          if (!streamDone.isCompleted) {
            streamDone.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!streamDone.isCompleted) streamDone.complete();
        },
        cancelOnError: true,
      );
      _activeStreamSubscription = subscription;

      await streamDone.future;
      if (cancelToken.isCanceled || receivedFallback) return;

      debounceTimer?.cancel();
      if (chunkBuffer.isNotEmpty) {
        final cleanChunk = chunkBuffer.toString();
        if (!processedChunks.contains(cleanChunk)) {
          await _appendAiText(
            cleanChunk,
            aiMessageIndex,
            thinkBuffer,
            formalBuffer,
            null,
          );
        }
      }

      if (!receivedAiContent) {
        _removeThinkingMessage();
        return;
      }

      final finalFormalContent = formalBuffer.toString();
      var finalThinkContent = thinkBuffer.toString();
      if (finalFormalContent.contains(
        RegExp(r'^\s*(\d+\.\s+|[-*]\s+)', multiLine: true),
      )) {
        finalThinkContent = '';
      }

      messages[aiMessageIndex] = ChatMessage(
        thinkContent: finalThinkContent,
        formalContent: 'DeepSeek: $finalFormalContent',
        isUser: false,
      );
    } catch (error, stackTrace) {
      if (cancelToken.isCanceled) {
        AppLogger.debug('AI stream canceled by user.');
        return;
      }
      AppLogger.error('AI stream failed', error: error, stackTrace: stackTrace);
      _removeThinkingMessage();
      _showFriendlyError('AI stream failed', details: error.toString());
      messages.add(ChatMessage(
        formalContent: 'Error: $error',
        isUser: false,
        isSystem: true,
      ));
    } finally {
      debounceTimer?.cancel();
      await _activeStreamSubscription?.cancel();
      _activeStreamSubscription = null;
      _activeCancelToken = null;
      isStreaming.value = false;
      loadingState.value = ChatLoadingState.idle;
    }
  }

  Future<void> _appendAiText(
    String text,
    int aiMessageIndex,
    StringBuffer thinkBuffer,
    StringBuffer formalBuffer,
    Timer? debounceTimer,
  ) async {
    final parts = _splitThinkAndFormal(text);
    final thinkPart = parts[0];
    final formalPart = parts[1];

    if (!enableWordStreaming.value) {
      thinkBuffer.write(thinkPart);
      formalBuffer.write(formalPart);
      debounceTimer?.cancel();
      return;
    }

    for (final word in _splitChineseWords(thinkPart)) {
      thinkBuffer.write(word);
      _updateAiMessage(aiMessageIndex, thinkBuffer, formalBuffer);
      await Future<void>.delayed(
          Duration(milliseconds: wordStreamDelayMs.value));
    }
    for (final word in _splitChineseWords(formalPart)) {
      formalBuffer.write(word);
      _updateAiMessage(aiMessageIndex, thinkBuffer, formalBuffer);
      await Future<void>.delayed(
          Duration(milliseconds: wordStreamDelayMs.value));
    }
  }

  void _updateAiMessage(
    int aiMessageIndex,
    StringBuffer thinkBuffer,
    StringBuffer formalBuffer,
  ) {
    if (aiMessageIndex < 0 || aiMessageIndex >= messages.length) return;
    messages[aiMessageIndex] = ChatMessage(
      thinkContent: thinkBuffer.toString(),
      formalContent: 'DeepSeek: ${formalBuffer.toString()}',
      isUser: false,
    );
  }

  void stopStreaming() {
    _cancelActiveStream();
  }

  void _cancelActiveStream() {
    _activeCancelToken?.cancel();
    unawaited(_activeStreamSubscription?.cancel() ?? Future<void>.value());
    _activeStreamSubscription = null;
    _activeCancelToken = null;
    isStreaming.value = false;
    loadingState.value = ChatLoadingState.idle;
    AppLogger.debug('SSE stream cancelled on page close');
  }

  List<Map<String, String>> _buildConversationWindow() {
    const maxHistory = 10;
    final visibleMessages = messages.where((message) {
      if (message.isSystem) return false;
      if (message.formalContent.startsWith('THINKING:')) return false;
      return _messageContentForHistory(message).isNotEmpty;
    }).toList();
    final recent = visibleMessages.length > maxHistory
        ? visibleMessages.sublist(visibleMessages.length - maxHistory)
        : visibleMessages;

    return recent
        .map((message) => {
              'role': message.isUser ? 'user' : 'assistant',
              'content': _messageContentForHistory(message),
            })
        .toList();
  }

  String _messageContentForHistory(ChatMessage message) {
    final content = message.formalContent.trim();
    if (!message.isUser && content.startsWith('DeepSeek:')) {
      return content.substring('DeepSeek:'.length).trim();
    }
    return content;
  }

  void _showContextLimitHint() {
    if (_contextLimitHintShown) return;
    _contextLimitHintShown = true;
    Get.snackbar('提示', '对话历史较长，较早的消息可能不会被考虑');
  }

  void _removeThinkingMessage() {
    if (messages.isNotEmpty &&
        messages.last.formalContent.startsWith('THINKING:')) {
      messages.removeLast();
    }
  }

  List<String> _splitThinkAndFormal(String text) {
    var thinkContent = '';
    var formalContent = text;

    final thinkRegex = RegExp(r'\[THINK\](.*?)\[/THINK\]', dotAll: true);
    final matches = thinkRegex.allMatches(text);
    for (final match in matches) {
      thinkContent += match.group(1)!.trim();
    }
    formalContent = text.replaceAll(thinkRegex, '').trim();

    return [thinkContent, formalContent];
  }

  List<String> _splitChineseWords(String text) {
    final regex = RegExp(r'[\u4e00-\u9fff]{1,4}|[^\u4e00-\u9fff\s]+|\s+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  void toggleWordStreaming(bool enable) {
    enableWordStreaming.value = enable;
    AppLogger.debug('Word streaming: $enable');
  }

  void setWordStreamDelay(int ms) {
    wordStreamDelayMs.value = ms.clamp(50, 300);
    AppLogger.debug('Word stream delay set to: $ms ms');
  }

  void clearMessages() {
    messages.clear();
    searchResults.clear();
    textController.clear();
    _sessionKey = null;
    _contextLimitHintShown = false;
  }

  void startNewConversation() {
    _cancelActiveStream();
    clearMessages();
  }

  void _showFriendlyError(String title, {String? details}) {
    final context = Get.context;
    if (context == null) {
      AppLogger.error('No context available for error dialog. $title $details');
      return;
    }
    final detailText = details == null || details.trim().isEmpty
        ? 'Please try again later.'
        : details.trim();
    AppDialog.showCustomDialog(
      context: context,
      title: title,
      content: Text(detailText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  void onClose() {
    _cancelActiveStream();
    textController.dispose();
    super.onClose();
  }
}
