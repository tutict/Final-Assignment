import 'package:w_transport/w_transport.dart' as transport;
import 'package:w_transport/vm.dart' show configureWTransportForVM;

class WebSocketService {
  transport.WebSocket? webSocket;
  final String websocketUrl = 'wss://localhost:8082/eventbus/users';

  WebSocketService() {
    configureWTransportForVM();
    _connect();
  }

  Future<void> _connect() async {
    try {
      webSocket = await transport.WebSocket.connect(Uri.parse(websocketUrl));
      if (webSocket == null) {
        throw Exception('Failed to connect to WebSocket');
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      // 这里你可以添加一些重试逻辑或者错误处理逻辑
    }
  }

  void sendMessage(String message) {
    webSocket?.add(message);
  }

  Stream<String> getMessages() {
    // 使用 `where` 过滤掉空消息
    return webSocket?.asBroadcastStream().where((event) => event.isNotEmpty).map((message) => message.toString()) ?? Stream.empty();
  }

  void close() {
    webSocket?.close();
  }
}
