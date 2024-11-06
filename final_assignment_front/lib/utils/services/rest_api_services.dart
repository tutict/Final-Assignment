import 'dart:convert';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

/// 定义消息模型
class MessageModel {
  final String action;
  final dynamic data;

  MessageModel({required this.action, required this.data});
}


/// 包含所有从服务器获取数据的服务。
class RestApiServices {
  // RestApiServices 的单例实例。
  static final RestApiServices _restApiServices = RestApiServices._internal();

  // 工厂方法，用于获取 RestApiServices 的单例实例。
  factory RestApiServices() {
    return _restApiServices;
  }

  // 私有构造函数，防止直接实例化。
  RestApiServices._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 日志记录器，用于记录操作信息
  final Logger logger = Logger('RestApiServices');

  // WebSocket 通道，用于建立和维护 WebSocket 连接
  late IOWebSocketChannel _channel;

  // MessageProvider 的引用
  MessageProvider? _messageProvider;

  // 初始化 WebSocket 连接
  void initWebSocket(String endpoint, MessageProvider messageProvider) async {
    _messageProvider = messageProvider;

    String? token = await getToken();
    if (token == null) {
      logger.warning('未找到 JWT 令牌，无法建立 WebSocket 连接');
      return;
    }

    // 构建 WebSocket URL
    final uri = getWsUrl(endpoint);

    // 设置请求头，包含 JWT 令牌
    final headers = {
      'Authorization': 'Bearer $token',
    };

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

  // 构建 WebSocket 服务的 URL 地址
  Uri getWsUrl(String endpoint) {
    // 检查是否使用了 HTTPS 协议，以决定使用 ws:// 或 wss://
    final isSecure = AppConfig.baseUrl.startsWith('https');
    final protocol = isSecure ? 'wss://' : 'ws://';

    // 去除 baseUrl 中的协议部分
    final baseUrl = AppConfig.baseUrl.replaceFirst(RegExp(r'^https?://'), '');

    return Uri.parse('$protocol$baseUrl$endpoint');
  }

  // 关闭 WebSocket 连接
  void closeWebSocket() {
    _channel.sink.close(status.normalClosure);
    logger.info('WebSocket 连接已关闭');
  }

  // 发送消息到 WebSocket
  void sendMessage(String message) {
    _channel.sink.add(message);
    logger.info('发送 WebSocket 消息: $message');
  }

  // 处理接收到的消息
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

  // 存储 JWT 令牌
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
    logger.info('JWT 令牌已保存');
  }

  // 获取 JWT 令牌
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // 删除 JWT 令牌
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'jwt_token');
    logger.info('JWT 令牌已删除');
  }
}
