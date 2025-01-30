import 'package:final_assignment_front/features/model/chat_response.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class ChatControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  ChatControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// getChatResponse with HTTP info returned
  ///
  ///
  Future<Response> apiAiChatGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/ai/chat".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// getChatResponse
  ///
  ///
  Future<Object?> apiAiChatGet() async {
    Response response = await apiAiChatGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'ChatResponse')
          as Object;
    } else {
      return null;
    }
  }

  /// 对应后端:
  ///   @WsAction(service="AiService", action="getChatResponse")
  ///   public ChatResponse getChatResponse() {...}
  ///
  Future<ChatResponse?> eventbusAiChatGet() async {
    // 构造要发送给后端的 WebSocket 消息
    final msg = {
      "service": "AiService", // 与后端@WsAction的 service 匹配
      "action": "getChatResponse", // 与后端@WsAction的 action 匹配
      "args": [] // 无参数
    };

    // 通过 WebSocket 发送消息
    final respMap = await apiClient.sendWsMessage(msg);

    // 如果后端返回错误，抛异常
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }

    // 正常返回 => result 里就是你的返回数据
    // 如果你有 ChatResponse.fromJson(...)，可像这样解析：
    if (respMap["result"] != null) {
      // 先把 result 转成 Map<String,dynamic>
      final resultMap = respMap["result"] as Map<String, dynamic>;
      return ChatResponse.fromJson(resultMap);
    }

    // 如果没有结果，就返回 null
    return null;
  }
}
