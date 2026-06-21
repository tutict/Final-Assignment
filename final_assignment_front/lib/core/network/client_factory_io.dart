import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

http.Client createHttpClient() => http.Client();

WebSocketChannel connectWebSocket(Uri uri, {Map<String, dynamic>? headers}) {
  return IOWebSocketChannel.connect(uri, headers: headers);
}
