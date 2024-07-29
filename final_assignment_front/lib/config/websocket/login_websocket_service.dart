import 'dart:async';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final wsUrl = Uri.parse('ws://localhost:8082/eventbus/users');
  final Logger logger = Logger('WebSocketService');
  late WebSocketChannel _channel;
  late StreamController _controller;

  WebSocketService() {
    _controller = StreamController();
    initWebSocket();
  }

  Future<void> initWebSocket() async {
    _channel = WebSocketChannel.connect(wsUrl);
    _channel.stream.listen((message) {
      _controller.add(message);
    });
  }

  void close() {
    _channel.sink.close();
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  Stream getMessages() {
    return _controller.stream;
  }
}
