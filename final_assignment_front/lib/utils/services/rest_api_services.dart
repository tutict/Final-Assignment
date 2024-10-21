import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // WebSocket 服务的 URL 地址
  Uri getWsUrl(String endpoint) {
    return Uri.parse(AppConfig.baseUrl + endpoint);
  }

  // 日志记录器，用于记录 WebSocketService 的操作信息
  final Logger logger = Logger('WebSocketService');

  // WebSocket 通道，用于建立和维护 WebSocket 连接
  late WebSocketChannel _channel;

  // 初始化 WebSocket 连接
  void initWebSocket(String endpoint) {
    _channel = WebSocketChannel.connect(getWsUrl(endpoint));
    _channel.stream.listen((message) {
      logger.info('WebSocket message received: $message');
    });
  }

  // 关闭 WebSocket 连接
  void closeWebSocket() {
    _channel.sink.close();
    logger.info('WebSocket connection closed');
  }

  // 发送消息到 WebSocket
  void sendMessage(String message) {
    _channel.sink.add(message);
    logger.info('WebSocket message sent: $message');
  }

  // 获取接收到的消息流
  Stream getMessages() {
    return _channel.stream;
  }

  // 存储 JWT 令牌
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
    logger.info('JWT token saved');
  }

  // 获取 JWT 令牌
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // 删除 JWT 令牌
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'jwt_token');
    logger.info('JWT token deleted');
  }

  // App 配置项
  static const String apiUrl = "https://api.example.com";
  static const int timeout = 5000;
}
