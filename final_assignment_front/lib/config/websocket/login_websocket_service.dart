import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sockjs_client_wrapper/sockjs_client_wrapper.dart';

class WebSocketService {
  late SockJSClient sockJS;
  final String websocketUrl = 'http://localhost:8082/eventbus/users';

  final Logger logger = Logger('WebSocketService');

  WebSocketService() {
    _connect();
  }

  void _connect() {
    final uri = Uri.parse(websocketUrl);
    final options = SockJSOptions(transports: ['websocket', 'xhr-streaming', 'xhr-polling']);
    sockJS = SockJSClient(uri, options: options);

    sockJS.onOpen.listen((event) {
      logger.info('OPEN: ${event.transport} ${event.url} ${event.debugUrl}');
    });

    sockJS.onMessage.listen((event) {
      logger.info('MSG: ${event.data}');
    });

    sockJS.onClose.listen((event) {
      logger.info('CLOSE: ${event.code} ${event.reason} (wasClean ${event.wasClean})');
    });

  }

  void sendMessage(String message) {
    sockJS.send(message);
  }

  Stream<String> getMessages() {
    return sockJS.onMessage.map((event) => event.data.toString()).where((message) => message.isNotEmpty);
  }

  void close() {
    sockJS.close();
  }
}

