import 'dart:convert';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/local_storage_services.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class RestApiServices {
  static final RestApiServices _instance = RestApiServices._internal();

  factory RestApiServices() => _instance;

  RestApiServices._internal();

  final Logger _logger = Logger('RestApiServices');
  IOWebSocketChannel? _channel;
  MessageProvider? _messageProvider;

  /// 初始化 WebSocket 连接
  Future<bool> initWebSocket(String endpoint, MessageProvider messageProvider) async {
    _messageProvider = messageProvider;

    try {
      String? token = await LocalStorageServices().getToken();
      if (token == null) {
        _logger.warning('JWT 令牌未找到，无法建立 WebSocket 连接');
        return false;
      }

      final uri = _buildWebSocketUri(endpoint, token);

      // 创建 WebSocket 连接
      _channel = IOWebSocketChannel.connect(uri);
      _logger.info('WebSocket 连接成功');

      _channel?.stream.listen(
            (message) {
          _logger.info('收到 WebSocket 消息: $message');
          _handleMessage(message);
        },
        onError: (error) {
          _logger.severe('WebSocket 错误: $error');
        },
        onDone: () {
          _logger.info('WebSocket 连接已关闭');
        },
        cancelOnError: true,
      );

      return true;
    } catch (e) {
      _logger.severe('WebSocket 初始化过程中发生错误: $e');
      return false;
    }
  }

  /// 构建 WebSocket 的 URI
  Uri _buildWebSocketUri(String endpoint, String token) {
    final isSecure = AppConfig.baseUrl.startsWith('https');
    final protocol = isSecure ? 'wss' : 'ws';
    final baseUri = Uri.parse(AppConfig.baseUrl);

    final queryParameters = {'token': token};

    return Uri(
      scheme: protocol,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : (isSecure ? 443 : 80),
      path: '${baseUri.path}$endpoint',
      queryParameters: queryParameters,
    );
  }

  /// 关闭 WebSocket 连接
  void closeWebSocket() {
    if (_channel != null) {
      _channel?.sink.close(status.normalClosure);
      _logger.info('WebSocket 连接已关闭');
    } else {
      _logger.warning('WebSocket 连接未建立，无需关闭');
    }
  }

  /// 发送消息到 WebSocket
  void sendMessage(String message) {
    if (_channel == null) {
      _logger.severe('WebSocket 连接尚未建立，无法发送消息');
      return;
    }
    try {
      _channel?.sink.add(message);
      _logger.info('发送 WebSocket 消息: $message');
    } catch (e) {
      _logger.severe('发送 WebSocket 消息时发生错误: $e');
    }
  }

  /// 处理收到的消息
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> decodedMessage = jsonDecode(message);

      if (decodedMessage.containsKey('action')) {
        final String action = decodedMessage['action'];
        final Map<String, dynamic> data = Map<String, dynamic>.from(decodedMessage)..remove('action');

        final messageModel = MessageModel(action: action, data: data);
        _messageProvider?.updateMessage(messageModel);
      } else {
        _logger.warning('收到的消息不包含 action 字段: $decodedMessage');
      }
    } catch (e) {
      _logger.severe('处理消息时发生错误: $e');
    }
  }
}

/// 定义消息模型
class MessageModel {
  final String action;
  final dynamic data;

  MessageModel({required this.action, required this.data});
}
