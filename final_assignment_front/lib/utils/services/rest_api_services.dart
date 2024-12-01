import 'dart:convert';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/local_storage_services.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

/// 包含所有从服务器获取数据的服务。
class RestApiServices {
  static final RestApiServices _restApiServices = RestApiServices._internal();

  factory RestApiServices() => _restApiServices;

  RestApiServices._internal();

  final Logger logger = Logger('RestApiServices');
  late IOWebSocketChannel _channel;
  MessageProvider? _messageProvider;

  void initWebSocket(String endpoint, MessageProvider messageProvider,
      {bool useSockJS = false}) async {
    _messageProvider = messageProvider;

    String? token = await LocalStorageServices().getToken();
    if (token == null) {
      logger.warning('JWT 令牌未找到，无法建立 WebSocket 连接');
      return;
    }

    final uri = getWsUrl(endpoint, token: token, useSockJS: useSockJS);

    // 设置请求头，包含 JWT 令牌
    final headers = {'Authorization': 'Bearer $token'};

    // 创建 WebSocket 连接
    _channel = IOWebSocketChannel.connect(uri, headers: headers);

    // 监听消息
    _channel.stream.listen(
      (message) {
        logger.info('收到 WebSocket 消息: $message');
        _handleMessage(message);
      },
      onError: (error) {
        logger.severe('WebSocket 错误: $error');
      },
      onDone: () {
        logger.info('WebSocket 连接已关闭');
      },
    );
  }

  Uri getWsUrl(String endpoint,
      {required String token, bool useSockJS = false}) {
    final isSecure = AppConfig.baseUrl.startsWith('https');
    final protocol = isSecure ? 'wss://' : 'ws://';
    final baseUrl = AppConfig.baseUrl.replaceFirst(RegExp(r'^https?://'), '');

    // 拼接 WebSocket URL，添加 token 参数和 SockJS 选项
    final Map<String, String> queryParameters = {'token': token};
    if (useSockJS) {
      queryParameters['useSockJS'] = 'true';
    }

    return Uri(
      scheme: protocol.startsWith('wss') ? 'wss' : 'ws',
      host: baseUrl.split(':')[0],
      port: int.tryParse(baseUrl.split(':')[1]) ?? (isSecure ? 443 : 80),
      path: endpoint,
      queryParameters: queryParameters,
    );
  }

  void closeWebSocket() {
    _channel.sink.close(status.normalClosure);
    logger.info('WebSocket 连接已关闭');
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
    logger.info('发送 WebSocket 消息: $message');
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> decodedMessage = jsonDecode(message);

      if (decodedMessage.containsKey('action')) {
        final String action = decodedMessage['action'];
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(decodedMessage);
        data.remove('action');

        final messageModel = MessageModel(action: action, data: data);
        _messageProvider?.updateMessage(messageModel);
      } else {
        logger.warning('收到的消息不包含 action 字段: $decodedMessage');
      }
    } catch (e) {
      logger.severe('处理消息时发生错误: $e');
    }
  }
}

/// 定义消息模型
class MessageModel {
  final String action;
  final dynamic data;

  MessageModel({required this.action, required this.data});
}
