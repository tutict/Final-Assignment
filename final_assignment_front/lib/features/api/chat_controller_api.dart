import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/features/model/chat_response.dart';
import 'package:final_assignment_front/features/model/chat_action_response.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class ChatControllerApi {
  final ApiClient apiClient;

  ChatControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<http.Response> apiAiChatGetWithHttpInfo(String message) async {
    Object postBody = '';
    String path = "/api/ai/chat".replaceAll("{format}", "json");
    // Use the new 'message' parameter (backend still accepts 'massage' as deprecated)
    List<QueryParam> queryParams = [QueryParam("message", message)];
    Map<String, String> headerParams = {};

      String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken != null) {
      headerParams['Authorization'] = 'Bearer $jwtToken';
      developer.log("JWT Token: $jwtToken", name: 'ChatControllerApi');
    } else {
      developer.log("No JWT token found in SharedPreferences",
          name: 'ChatControllerApi');
    }

    return await apiClient.invokeAPI(
        path, 'GET', queryParams, postBody, headerParams, {}, null, []);
  }

  Future<String?> apiAiChatGet(String message) async {
    try {
      http.Response response = await apiAiChatGetWithHttpInfo(message);
      String decodedBody =
          utf8.decode(response.bodyBytes, allowMalformed: true);
      developer.log("Decoded response body: $decodedBody",
          name: 'ChatControllerApi');

      if (response.statusCode >= 400) {
        throw Exception("API request failed: $decodedBody");
      }
      if (decodedBody.isNotEmpty) {
        final jsonResponse = jsonDecode(decodedBody);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse['message'] != null) {
          String rawMessage = jsonResponse['message'].toString();
          String processedMessage = removeMarkdown(rawMessage);
          developer.log("Processed AI response: $processedMessage",
              name: 'ChatControllerApi');
          return processedMessage;
        }
        developer.log("No valid 'message' field in response: $decodedBody",
            name: 'ChatControllerApi');
        return "No valid response from AI.";
      }
      developer.log("Empty response body", name: 'ChatControllerApi');
      return "AI returned an empty response.";
    } catch (e) {
      developer.log("Error in apiAiChatGet: $e", name: 'ChatControllerApi');
      throw Exception("Failed to process AI response: $e");
    }
  }

  Future<http.Response> apiAiChatActionsGetWithHttpInfo(
      String message, bool webSearch) async {
    Object postBody = '';
    String path = "/api/ai/chat/actions".replaceAll("{format}", "json");
    List<QueryParam> queryParams = [
      QueryParam("message", message),
      QueryParam("webSearch", webSearch.toString())
    ];
    Map<String, String> headerParams = {};

      String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken != null) {
      headerParams['Authorization'] = 'Bearer $jwtToken';
      developer.log("JWT Token: $jwtToken", name: 'ChatControllerApi');
    } else {
      developer.log("No JWT token found in SharedPreferences",
          name: 'ChatControllerApi');
    }

    return await apiClient.invokeAPI(
        path, 'GET', queryParams, postBody, headerParams, {}, null, []);
  }

  Future<ChatActionResponse?> apiAiChatActionsGet(
      String message, bool webSearch) async {
    try {
      http.Response response =
          await apiAiChatActionsGetWithHttpInfo(message, webSearch);
      String decodedBody =
          utf8.decode(response.bodyBytes, allowMalformed: true);
      developer.log("Decoded response body: $decodedBody",
          name: 'ChatControllerApi');

      if (response.statusCode >= 400) {
        throw Exception("API request failed: $decodedBody");
      }
      if (decodedBody.isNotEmpty) {
        final jsonResponse = jsonDecode(decodedBody);
        if (jsonResponse is Map<String, dynamic>) {
          return ChatActionResponse.fromJson(jsonResponse);
        }
        developer.log("No valid JSON object in response: $decodedBody",
            name: 'ChatControllerApi');
        return null;
      }
      developer.log("Empty response body", name: 'ChatControllerApi');
      return null;
    } catch (e) {
      developer.log("Error in apiAiChatActionsGet: $e",
          name: 'ChatControllerApi');
      throw Exception("Failed to process AI actions response: $e");
    }
  }

  Stream<String> apiAiChatStream(String message, bool webSearch) async* {
      String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    Map<String, String> headers = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };

    if (jwtToken != null) {
      headers['Authorization'] = 'Bearer $jwtToken';
      developer.log("JWT Token for stream: $jwtToken",
          name: 'ChatControllerApi');
    } else {
      developer.log("No JWT token found for stream", name: 'ChatControllerApi');
    }

    // Stream via the configured gateway/base path
    final base = apiClient.basePath.endsWith('/')
        ? apiClient.basePath.substring(0, apiClient.basePath.length - 1)
        : apiClient.basePath;
    final uri =
        Uri.parse('$base/api/ai/chat?message=$message&webSearch=$webSearch');
    final request = http.Request('GET', uri)..headers.addAll(headers);

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        developer.log(
            "Stream request failed with status: ${response.statusCode}",
            name: 'ChatControllerApi');
        throw Exception('Stream request failed: ${response.statusCode}');
      }

      StringBuffer dataBuffer = StringBuffer();
      Set<String> processedChunks = {}; // Deduplication set

      await for (final data in response.stream.transform(utf8.decoder)) {
        dataBuffer.write(data);
        String bufferedData = dataBuffer.toString();
        developer.log("Raw buffered data: $bufferedData",
            name: 'ChatControllerApi');

// Split by lines, process complete lines
        List<String> lines = bufferedData.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          String line = lines[i].trim();
          if (line.startsWith('data:') && line.length > 5) {
            int colonIndex = line.indexOf(':');
            if (colonIndex != -1) {
              String jsonString = line.substring(colonIndex + 1).trim();
              try {
                final jsonData = jsonDecode(jsonString);
                if (jsonData is Map<String, dynamic>) {
                  if (jsonData['message'] != null) {
                    String rawMessage = jsonData['message'].toString();
                    String processedMessage = removeMarkdown(rawMessage);
// Deduplicate
                    if (processedMessage.isNotEmpty &&
                        !processedChunks.contains(processedMessage)) {
                      processedChunks.add(processedMessage);
                      developer.log("Yielding message: $processedMessage",
                          name: 'ChatControllerApi');
                      yield processedMessage;
                    }
                  } else if (jsonData['searchResults'] != null) {
                    String searchResult = '[搜索结果] ${jsonData['searchResults']}';
                    if (!processedChunks.contains(searchResult)) {
                      processedChunks.add(searchResult);
                      developer.log("Yielding search result: $searchResult",
                          name: 'ChatControllerApi');
                      yield searchResult;
                    }
                  }
                }
              } catch (e) {
                developer.log(
                    "Failed to parse SSE chunk: '$jsonString', error: $e",
                    name: 'ChatControllerApi');
              }
            }
          }
        }

// Keep only the last (potentially incomplete) line
        dataBuffer = StringBuffer(lines.last.isNotEmpty ? lines.last : '');
        developer.log("Remaining buffer: ${dataBuffer.toString()}",
            name: 'ChatControllerApi');
      }

// Process any remaining data
      String remainingData = dataBuffer.toString().trim();
      if (remainingData.startsWith('data:') && remainingData.length > 5) {
        int colonIndex = remainingData.indexOf(':');
        if (colonIndex != -1) {
          String jsonString = remainingData.substring(colonIndex + 1).trim();
          try {
            final jsonData = jsonDecode(jsonString);
            if (jsonData is Map<String, dynamic>) {
              if (jsonData['message'] != null) {
                String rawMessage = jsonData['message'].toString();
                String processedMessage = removeMarkdown(rawMessage);
                if (processedMessage.isNotEmpty &&
                    !processedChunks.contains(processedMessage)) {
                  processedChunks.add(processedMessage);
                  developer.log("Yielding final message: $processedMessage",
                      name: 'ChatControllerApi');
                  yield processedMessage;
                }
              } else if (jsonData['searchResults'] != null) {
                String searchResult = '[搜索结果] ${jsonData['searchResults']}';
                if (!processedChunks.contains(searchResult)) {
                  processedChunks.add(searchResult);
                  developer.log("Yielding final search result: $searchResult",
                      name: 'ChatControllerApi');
                  yield searchResult;
                }
              }
            }
          } catch (e) {
            developer.log(
                "Failed to parse final SSE chunk: '$jsonString', error: $e",
                name: 'ChatControllerApi');
          }
        }
      }
    } catch (e) {
      developer.log("Stream error: $e", name: 'ChatControllerApi');
      rethrow;
    } finally {
      client.close();
    }
  }

  String removeMarkdown(String text) {
    text = text.replaceAllMapped(RegExp(r'<think>([\s\S]*?)</think>'),
        (match) => '[THINK]${match.group(1)}[/THINK]');
    text = text.replaceAll(RegExp(r'</?think>'), '');
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'##(.*?)##'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'_(.*?)_'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'-(.*?)-'), (match) => match.group(1)!);
    text = text.replaceAllMapped(
        RegExp(r'###(.*?)###'), (match) => match.group(1)!);
    return text.trim();
  }

  Future<ChatResponse?> eventbusAiChatGet() async {
    final msg = {
      "service": "AiService",
      "action": "getChatResponse",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      final resultMap = respMap["result"] as Map<String, dynamic>;
      return ChatResponse.fromJson(resultMap);
    }
    return null;
  }
}
