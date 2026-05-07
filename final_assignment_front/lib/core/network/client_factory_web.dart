import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

http.Client createHttpClient() => BrowserClient();

WebSocketChannel connectWebSocket(Uri uri, {Map<String, dynamic>? headers}) {
  // Browser WebSocket cannot send custom Authorization headers.
  // Put a short-lived token in the query string or rely on cookie auth on Web.
  return HtmlWebSocketChannel.connect(uri);
}
