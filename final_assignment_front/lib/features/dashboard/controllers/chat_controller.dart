import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/api/chat_controller_api.dart';

class ChatMessage {
  final String thinkContent;
  final String formalContent;
  final bool isUser;

  ChatMessage({
    this.thinkContent = '',
    this.formalContent = '',
    required this.isUser,
  });
}

class ChatController extends GetxController {
  static ChatController get to => Get.find();

  final messages = <ChatMessage>[].obs;
  final searchResults = <String>[].obs;
  final TextEditingController textController = TextEditingController();
  final ChatControllerApi chatApi = ChatControllerApi();

  final RxString userRole = "USER".obs;
  final RxBool enableWordStreaming = true.obs;
  final RxInt wordStreamDelayMs = 150.obs;
  final RxBool webSearchEnabled = false.obs;

  void setUserRole(String role) {
    userRole.value = role.toUpperCase();
    debugPrint('ChatController: User role set to $role');
  }

  void toggleWebSearch(bool enable) {
    webSearchEnabled.value = enable;
    debugPrint('Web search enabled: $enable');
  }

  Future<void> sendMessage() async {
    final String text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(ChatMessage(formalContent: text, isUser: true));
    debugPrint('添加用户消息: $text');
    textController.clear();

    try {
      messages.add(ChatMessage(formalContent: "DeepSeek: ", isUser: false));
      int aiMessageIndex = messages.length - 1;
      StringBuffer thinkBuffer = StringBuffer();
      StringBuffer formalBuffer = StringBuffer();
      StringBuffer chunkBuffer = StringBuffer();
      Timer? debounceTimer;
      Set<String> processedChunks = {}; // Deduplication set

      await for (String chunk
          in chatApi.apiAiChatStream(text, webSearchEnabled.value)) {
// Skip if chunk already processed
        if (processedChunks.contains(chunk)) {
          debugPrint('Skipping duplicate chunk: $chunk');
          continue;
        }
        processedChunks.add(chunk);
        debugPrint('Processing chunk: $chunk');

        if (chunk.startsWith('[搜索结果]') && webSearchEnabled.value) {
          searchResults.add(chunk.substring(7));
          debugPrint('收到搜索结果: ${chunk.substring(7)}');
          continue;
        }

        chunkBuffer.write(chunk);

        if (chunkBuffer.length > 100 || !(debounceTimer?.isActive ?? false)) {
          String cleanChunk = chunkBuffer.toString();
          chunkBuffer.clear();

          List<String> parts = _splitThinkAndFormal(cleanChunk);
          String thinkPart = parts[0];
          String formalPart = parts[1];

          if (enableWordStreaming.value) {
            if (thinkPart.isNotEmpty) {
              List<String> words = _splitChineseWords(thinkPart);
              for (String word in words) {
                thinkBuffer.write(word);
                messages[aiMessageIndex] = ChatMessage(
                  thinkContent: thinkBuffer.toString(),
                  formalContent: "DeepSeek: ${formalBuffer.toString()}",
                  isUser: false,
                );
                await Future.delayed(
                    Duration(milliseconds: wordStreamDelayMs.value));
              }
            }
            if (formalPart.isNotEmpty) {
              List<String> words = _splitChineseWords(formalPart);
              for (String word in words) {
                formalBuffer.write(word);
                messages[aiMessageIndex] = ChatMessage(
                  thinkContent: thinkBuffer.toString(),
                  formalContent: "DeepSeek: ${formalBuffer.toString()}",
                  isUser: false,
                );
                await Future.delayed(
                    Duration(milliseconds: wordStreamDelayMs.value));
              }
            }
          } else {
            thinkBuffer.write(thinkPart);
            formalBuffer.write(formalPart);
            if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
            debounceTimer = Timer(const Duration(milliseconds: 100), () {
              messages[aiMessageIndex] = ChatMessage(
                thinkContent: thinkBuffer.toString(),
                formalContent: "DeepSeek: ${formalBuffer.toString()}",
                isUser: false,
              );
            });
          }
        }
      }

// Process remaining buffer
      if (chunkBuffer.isNotEmpty) {
        String cleanChunk = chunkBuffer.toString();
        if (!processedChunks.contains(cleanChunk)) {
          processedChunks.add(cleanChunk);
          debugPrint('Processing final chunk: $cleanChunk');
          List<String> parts = _splitThinkAndFormal(cleanChunk);
          String thinkPart = parts[0];
          String formalPart = parts[1];

          if (enableWordStreaming.value) {
            if (thinkPart.isNotEmpty) {
              List<String> words = _splitChineseWords(thinkPart);
              for (String word in words) {
                thinkBuffer.write(word);
                messages[aiMessageIndex] = ChatMessage(
                  thinkContent: thinkBuffer.toString(),
                  formalContent: "DeepSeek: ${formalBuffer.toString()}",
                  isUser: false,
                );
                await Future.delayed(
                    Duration(milliseconds: wordStreamDelayMs.value));
              }
            }
            if (formalPart.isNotEmpty) {
              List<String> words = _splitChineseWords(formalPart);
              for (String word in words) {
                formalBuffer.write(word);
                messages[aiMessageIndex] = ChatMessage(
                  thinkContent: thinkBuffer.toString(),
                  formalContent: "DeepSeek: ${formalBuffer.toString()}",
                  isUser: false,
                );
                await Future.delayed(
                    Duration(milliseconds: wordStreamDelayMs.value));
              }
            }
          } else {
            thinkBuffer.write(thinkPart);
            formalBuffer.write(formalPart);
          }
        }
      }

      if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
      messages[aiMessageIndex] = ChatMessage(
        thinkContent: thinkBuffer.toString(),
        formalContent: "DeepSeek: ${formalBuffer.toString()}",
        isUser: false,
      );

      debugPrint('AI 流完成: $text');
    } catch (e) {
      debugPrint('流式 AI 响应错误: $e');
      messages.add(ChatMessage(formalContent: "错误: $e", isUser: false));
    }
  }

  List<String> _splitThinkAndFormal(String text) {
    String thinkContent = '';
    String formalContent = text;

    RegExp thinkRegex = RegExp(r'\[THINK\](.*?)\[/THINK\]');
    Iterable<Match> matches = thinkRegex.allMatches(text);
    for (Match match in matches) {
      thinkContent += match.group(1)!;
    }
    formalContent = text.replaceAll(thinkRegex, '').trim();

    return [thinkContent, formalContent];
  }

  List<String> _splitChineseWords(String text) {
    RegExp regex = RegExp(r'[\u4e00-\u9fff]{1,4}|[^\u4e00-\u9fff\s]+|\s+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  void toggleWordStreaming(bool enable) {
    enableWordStreaming.value = enable;
    debugPrint('Word streaming: $enable');
  }

  void setWordStreamDelay(int ms) {
    wordStreamDelayMs.value = ms.clamp(50, 300);
    debugPrint('Word stream delay set to: $ms ms');
  }

  void clearMessages() {
    messages.clear();
    searchResults.clear();
    textController.clear();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
