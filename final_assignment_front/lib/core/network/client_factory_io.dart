import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

http.Client createHttpClient() => http.Client();

WebSocketChannel connectWebSocket(Uri uri, {Map<String, dynamic>? headers}) {
  return WebSocketChannel.connect(uri);
}
