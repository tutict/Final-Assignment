import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:http/http.dart' as http;

import 'ai_stream_event.dart';
import 'sse_streaming_parser.dart';

class CancelToken {
  bool _isCanceled = false;
  final List<void Function()> _callbacks = [];

  bool get isCanceled => _isCanceled;

  void cancel() {
    if (_isCanceled) return;
    _isCanceled = true;
    for (final callback in List<void Function()>.from(_callbacks)) {
      callback();
    }
    _callbacks.clear();
  }

  void _onCancel(void Function() callback) {
    if (_isCanceled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }
}

class AiChatApi {
  AiChatApi({
    ApiClient? apiClient,
    http.Client Function()? clientFactory,
  })  : apiClient = apiClient ?? ApiClient(),
        _clientFactory = clientFactory ?? (() => http.Client());

  final ApiClient apiClient;
  final http.Client Function() _clientFactory;

  Stream<AiStreamEvent> streamChat({
    required String message,
    String? sessionKey,
    Map<String, Object?> metadata = const {},
    CancelToken? cancelToken,
  }) {
    late StreamController<AiStreamEvent> controller;
    http.Client? client;
    StreamSubscription<AiStreamEvent>? subscription;
    var closed = false;

    Future<void> stop() async {
      if (closed) return;
      closed = true;
      await subscription?.cancel();
      client?.close();
    }

    Future<void> closeController() async {
      await stop();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    Future<void> start() async {
      if (cancelToken?.isCanceled ?? false) {
        await closeController();
        return;
      }

      client = _clientFactory();
      cancelToken?._onCancel(() {
        closeController();
      });

      try {
        final request = http.Request('POST', _streamUri())
          ..headers.addAll(await _headers())
          ..body = jsonEncode({
            'message': message,
            if (sessionKey != null && sessionKey.isNotEmpty)
              'sessionKey': sessionKey,
            if (metadata.isNotEmpty) 'metadata': metadata,
          });

        final response = await client!.send(request);
        if (cancelToken?.isCanceled ?? false) {
          await closeController();
          return;
        }

        if (response.statusCode >= 400) {
          controller.add(AiStreamEvent.error(
            'AI stream request failed: ${response.statusCode}',
          ));
          await closeController();
          return;
        }

        subscription = response.stream
            .transform(utf8.decoder)
            .transform(const SseStreamingParser())
            .listen(
          controller.add,
          onError: (Object error) {
            if (!controller.isClosed) {
              controller.add(AiStreamEvent.error(error.toString()));
            }
            closeController();
          },
          onDone: () {
            closeController();
          },
        );
      } catch (error) {
        if (!(cancelToken?.isCanceled ?? false) && !controller.isClosed) {
          controller.add(AiStreamEvent.error(error.toString()));
        }
        await closeController();
      }
    }

    controller = StreamController<AiStreamEvent>(
      onListen: () {
        start();
      },
      onCancel: () async {
        cancelToken?.cancel();
        await stop();
      },
    );

    return controller.stream;
  }

  Uri _streamUri() {
    final base = apiClient.basePath.endsWith('/')
        ? apiClient.basePath.substring(0, apiClient.basePath.length - 1)
        : apiClient.basePath;
    return Uri.parse('$base/api/ai/chat/stream');
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken != null && jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }
    return headers;
  }
}
