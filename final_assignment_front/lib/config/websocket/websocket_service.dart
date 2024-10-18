import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocketService类用于管理WebSocket连接，包括连接建立、消息发送、消息监听和关闭连接
class WebSocketService {
  /// _channel用于存储WebSocket连接通道
  WebSocketChannel? _channel;

  /// wsUrl是WebSocket服务的URL地址
  final String wsUrl;

  /// 构造函数，需要传入WebSocket服务的URL地址
  WebSocketService({required this.wsUrl});

  /// 连接WebSocket服务
  void connect() {
    // 根据传入的URL地址建立WebSocket连接
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  /// 发送消息到WebSocket服务
  ///
  /// 参数: message是要发送的消息字符串
  void sendMessage(String message) {
    // 如果_channel不为空，则通过_channel的sink添加消息
    _channel?.sink.add(message);
  }

  /// 监听WebSocket服务的消息
  ///
  /// 参数: onMessage是收到消息时的回调函数，接受一个动态类型的消息参数
  void listenMessages(Function(dynamic) onMessage) {
    // 如果_channel不为空，则监听_channel的stream，收到消息时调用onMessage回调
    _channel?.stream.listen((message) {
      onMessage(message);
    });
  }

  /// 关闭WebSocket连接
  void close() {
    // 如果_channel不为空，则通过_channel的sink关闭连接
    _channel?.sink.close();
  }
}

