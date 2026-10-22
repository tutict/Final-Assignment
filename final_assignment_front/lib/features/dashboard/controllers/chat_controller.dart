import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/ai/ai_chat_identity.dart';
import 'package:final_assignment_front/features/ai/business_action_catalog.dart';
import 'package:final_assignment_front/features/ai/business_chat_agent.dart';
import 'package:final_assignment_front/features/ai/ai_chat_api.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';
import 'package:final_assignment_front/features/model/chat_action.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/chat_action_executor.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatMessage {
  const ChatMessage({
    this.thinkContent = '',
    this.formalContent = '',
    required this.isUser,
    this.isSystem = false,
    this.actions = const [],
    this.needConfirm = false,
  });

  final String thinkContent;
  final String formalContent;
  final bool isUser;
  final bool isSystem;
  final List<ChatAction> actions;
  final bool needConfirm;
}

enum ChatLoadingState { idle, thinking, searching, generating, queuing }

class ChatController extends GetxController {
  static ChatController get to => Get.find();
  static const Duration _streamUiTimeout = Duration(seconds: 75);

  final messages = <ChatMessage>[].obs;
  final searchResults = <String>[].obs;
  final TextEditingController textController = TextEditingController();
  final ChatControllerApi chatApi = ChatControllerApi();
  final BusinessChatAgent businessAgent = const BusinessChatAgent();

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

  bool get isAdminRole => RoleUtils.isAdminRole(userRole.value);

  bool get isSuperAdminRole => RoleUtils.isSuperAdminRole(userRole.value);

  bool get canUseManagerPrompts =>
      RoleUtils.canAccessAdminDashboard(userRole.value);

  bool get isUserFacingChat => !canUseManagerPrompts;

  String get loadingText {
    return switch (loadingState.value) {
      ChatLoadingState.idle => '',
      ChatLoadingState.thinking => '思考中...',
      ChatLoadingState.searching => '正在搜索相关信息...',
      ChatLoadingState.generating => '生成中...',
      ChatLoadingState.queuing => '正在排队',
    };
  }

  void setUserRole(String role) {
    userRole.value = RoleUtils.preferredRole(role);
    AppLogger.debug('ChatController: User role set to ${userRole.value}');
  }

  void toggleWebSearch(bool enable) {
    webSearchEnabled.value = enable;
    AppLogger.debug('Web search enabled: $enable');
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isStreaming.value) return;

    _removeThinkingMessages();
    final conversationWindow = _buildConversationWindow();
    if (messages.length >= 20) {
      _showContextLimitHint();
    }

    // 本地关键词代理只作为兜底：后端 agent 下发的动作优先级更高。
    final businessAction =
        businessAgent.resolve(message: text, role: userRole.value);
    final localActions = _normalizeActions(businessAction?.actions ?? const []);
    messages.add(ChatMessage(formalContent: text, isUser: true));
    textController.clear();

    loadingState.value = webSearchEnabled.value
        ? ChatLoadingState.searching
        : ChatLoadingState.thinking;
    messages.add(ChatMessage(
      formalContent: webSearchEnabled.value
          ? 'THINKING: Searching...'
          : 'THINKING: Thinking...',
      isUser: false,
    ));

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;
    isStreaming.value = true;

    final draft = _AiMessageDraft(messages.length - 1, localActions);
    final chunkBuffer = StringBuffer();
    final processedChunks = <String>{};
    Timer? debounceTimer;
    Timer? uiTimeoutTimer;
    var isFirstMessage = true;
    var receivedFallback = false;
    var receivedAiContent = false;
    var timedOut = false;

    Future<void> processChunk(ChatStreamChunk streamChunk) async {
      if (cancelToken.isCanceled) return;

      if (_sessionKey == null && streamChunk.sessionKey != null) {
        _sessionKey = streamChunk.sessionKey;
      }

      if (streamChunk.actions.isNotEmpty) {
        draft.addBackendActions(_normalizeActions(streamChunk.actions));
        _syncDraftActions(draft);
        return;
      }

      final chunk = streamChunk.text;
      if (streamChunk.isQueue) {
        loadingState.value = ChatLoadingState.queuing;
        if (draft.messageIndex >= 0 &&
            draft.messageIndex < messages.length &&
            messages[draft.messageIndex].formalContent.startsWith('THINKING:')) {
          messages[draft.messageIndex] = const ChatMessage(
            formalContent: 'THINKING: Queuing...',
            isUser: false,
          );
        }
        return;
      }

      if (streamChunk.isFallback) {
        receivedFallback = true;
        _removeThinkingMessages();
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
        _removeThinkingMessages();
        messages.add(ChatMessage(
          formalContent: AiChatIdentity.prefix,
          isUser: false,
          actions: draft.actions,
        ));
        draft.messageIndex = messages.length - 1;
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
        draft,
        debounceTimer,
      );
      if (!enableWordStreaming.value) {
        debounceTimer = Timer(const Duration(milliseconds: 100), () {
          _updateAiMessage(draft);
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
      uiTimeoutTimer = Timer(_streamUiTimeout, () {
        if (streamDone.isCompleted || cancelToken.isCanceled) return;
        timedOut = true;
        cancelToken.cancel();
        streamDone.completeError(
          TimeoutException(
            'AI response timed out',
            _streamUiTimeout,
          ),
          StackTrace.current,
        );
        unawaited(subscription.cancel());
      });

      await streamDone.future;
      if (cancelToken.isCanceled || receivedFallback) return;

      debounceTimer?.cancel();
      if (chunkBuffer.isNotEmpty) {
        final cleanChunk = chunkBuffer.toString();
        if (!processedChunks.contains(cleanChunk)) {
          await _appendAiText(
            cleanChunk,
            draft,
            null,
          );
        }
      }

      if (!receivedAiContent) {
        _removeThinkingMessages();
        messages.add(ChatMessage(
          formalContent: businessAction?.answer ?? '暂时没有生成回复，请稍后再试。',
          isUser: false,
          isSystem: true,
          actions: draft.actions,
          needConfirm: businessAction?.needConfirm ?? false,
        ));
        return;
      }

      final finalFormalContent =
          chatApi.removeMarkdown(draft.formalBuffer.toString());
      var finalThinkContent =
          chatApi.removeMarkdown(draft.thinkBuffer.toString());
      if (finalFormalContent.contains(
        RegExp(r'^\s*(\d+\.\s+|[-*]\s+)', multiLine: true),
      )) {
        finalThinkContent = '';
      }

      messages[draft.messageIndex] = ChatMessage(
        thinkContent: finalThinkContent,
        formalContent: '${AiChatIdentity.prefix}$finalFormalContent',
        isUser: false,
        actions: draft.actions,
      );
    } catch (error, stackTrace) {
      if (cancelToken.isCanceled && !timedOut) {
        AppLogger.debug('AI stream canceled by user.');
        return;
      }
      AppLogger.error('AI stream failed', error: error, stackTrace: stackTrace);
      _removeThinkingMessages();
      _showFriendlyError('AI stream failed', details: error.toString());
      messages.add(ChatMessage(
        formalContent: localActions.isNotEmpty
            ? (businessAction?.answer ?? 'AI 服务暂时不可用，请稍后再试。')
            : 'Error: $error',
        isUser: false,
        isSystem: true,
        actions: localActions,
        needConfirm: businessAction?.needConfirm ?? false,
      ));
    } finally {
      uiTimeoutTimer?.cancel();
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
    _AiMessageDraft draft,
    Timer? debounceTimer,
  ) async {
    final parts = _splitThinkAndFormal(text);
    final thinkPart = parts[0];
    final formalPart = parts[1];

    if (!enableWordStreaming.value) {
      draft.thinkBuffer.write(thinkPart);
      draft.formalBuffer.write(formalPart);
      debounceTimer?.cancel();
      return;
    }

    for (final word in _splitChineseWords(thinkPart)) {
      draft.thinkBuffer.write(word);
      _updateAiMessage(draft);
      await Future<void>.delayed(
          Duration(milliseconds: wordStreamDelayMs.value));
    }
    for (final word in _splitChineseWords(formalPart)) {
      draft.formalBuffer.write(word);
      _updateAiMessage(draft);
      await Future<void>.delayed(
          Duration(milliseconds: wordStreamDelayMs.value));
    }
  }

  void _updateAiMessage(_AiMessageDraft draft) {
    final index = draft.messageIndex;
    if (index < 0 || index >= messages.length) return;
    // 逐 token 清洗无法匹配被拆到不同分片里的 "**"，因此对累计文本再整体清洗一次。
    messages[index] = ChatMessage(
      thinkContent: chatApi.removeMarkdown(draft.thinkBuffer.toString()),
      formalContent: '${AiChatIdentity.prefix}'
          '${chatApi.removeMarkdown(draft.formalBuffer.toString(), trim: false)}',
      isUser: false,
      actions: draft.actions,
    );
  }

  /// 把后端或本地代理下发的动作归一化成统一文案与路由。
  List<ChatAction> _normalizeActions(List<ChatAction> actions) {
    if (actions.isEmpty) return const [];
    final isStaff = canUseManagerPrompts;
    final normalized = <ChatAction>[];
    for (final action in actions) {
      final entry =
          BusinessActionCatalog.resolve(action.target, isStaff: isStaff);
      if (entry == null) {
        normalized.add(action);
        continue;
      }
      normalized.add(ChatAction(
        type: action.type ?? 'NAVIGATE',
        label: entry.label,
        target: entry.route,
        value: action.value,
      ));
    }
    return normalized;
  }

  /// 动作先于正文到达时，把按钮补到已经渲染的助手消息上。
  void _syncDraftActions(_AiMessageDraft draft) {
    final index = draft.messageIndex;
    if (index < 0 || index >= messages.length) return;
    final current = messages[index];
    if (current.formalContent.startsWith('THINKING:')) return;
    messages[index] = ChatMessage(
      thinkContent: current.thinkContent,
      formalContent: current.formalContent,
      isUser: false,
      actions: draft.actions,
    );
  }

  void stopStreaming() {
    _cancelActiveStream();
  }

  Future<void> executeAction(ChatAction action,
      {bool needConfirm = false}) async {
    final executor = ChatActionExecutor(
      context: Get.context,
      onNavigate: _navigateByAction,
      onFillForm: _navigateByAction,
    );
    await executor.executeActions([action], needConfirm: needConfirm);
  }

  Future<void> _navigateByAction(ChatAction action) async {
    final target = action.target?.trim();
    if (target == null || target.isEmpty) {
      Get.snackbar('无法执行', '该动作没有配置目标页面');
      return;
    }

    await NavigationHelper.toNamed(
      target,
      arguments: _decodeActionArguments(action),
      fallback: RoleUtils.canAccessAdminDashboard(userRole.value)
          ? Routes.dashboard
          : Routes.userDashboard,
    );
  }

  Map<String, dynamic> _decodeActionArguments(ChatAction action) {
    final result = <String, dynamic>{
      'agentAction': action.toJson(),
    };
    final value = action.value;
    if (value == null || value.trim().isEmpty) {
      return result;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        result.addAll(decoded);
      } else {
        result['agentPrefill'] = {'value': decoded};
      }
    } catch (_) {
      result['agentPrefill'] = {'value': value};
    }
    return result;
  }

  void _cancelActiveStream() {
    _activeCancelToken?.cancel();
    unawaited(_activeStreamSubscription?.cancel() ?? Future<void>.value());
    _activeStreamSubscription = null;
    _activeCancelToken = null;
    _removeThinkingMessages();
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
    if (message.isUser) return content;
    return AiChatIdentity.stripPrefix(content);
  }

  void _showContextLimitHint() {
    if (_contextLimitHintShown) return;
    _contextLimitHintShown = true;
    Get.snackbar('提示', '对话历史较长，较早的消息可能不会被考虑');
  }

  void _removeThinkingMessages() {
    messages.removeWhere(
      (message) => message.formalContent.startsWith('THINKING:'),
    );
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

/// 一次流式回答的草稿状态：记录正文、思考过程与已收集到的业务动作。
class _AiMessageDraft {
  _AiMessageDraft(this.messageIndex, this.fallbackActions);

  int messageIndex;

  /// 后端没有给出动作时使用的本地兜底动作。
  final List<ChatAction> fallbackActions;

  /// 后端 agent 下发的动作，优先级高于本地兜底动作。
  final List<ChatAction> backendActions = <ChatAction>[];

  final StringBuffer thinkBuffer = StringBuffer();
  final StringBuffer formalBuffer = StringBuffer();

  List<ChatAction> get actions => List<ChatAction>.unmodifiable(
        backendActions.isNotEmpty ? backendActions : fallbackActions,
      );

  void addBackendActions(List<ChatAction> actions) {
    for (final action in actions) {
      final duplicated = backendActions.any(
        (existing) =>
            existing.label == action.label && existing.target == action.target,
      );
      if (!duplicated) backendActions.add(action);
    }
  }
}
