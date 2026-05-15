import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:get/get.dart';
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
  static const Duration _sseTimeout = Duration(seconds: 120);
  static const Duration _firstTokenTimeout = Duration(seconds: 30);

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
    StreamSubscription<AiStreamEvent>? subscription;
    Timer? firstTokenTimer;
    Timer? overallTimer;
    var receivedFirstToken = false;
    var closed = false;

    Future<void> stop() async {
      if (closed) return;
      closed = true;
      firstTokenTimer?.cancel();
      overallTimer?.cancel();
      await subscription?.cancel();
    }

    Future<void> closeController() async {
      await stop();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    void completeFirstToken() {
      if (receivedFirstToken) return;
      receivedFirstToken = true;
      firstTokenTimer?.cancel();
    }

    void addStreamError(Object error) {
      if (!controller.isClosed) {
        controller.addError(AppException.fromError(error));
      }
    }

    Future<void> start() async {
      if (cancelToken?.isCanceled ?? false) {
        await closeController();
        return;
      }

      subscription = _streamWithAuthRetry(
        message: message,
        sessionKey: sessionKey,
        metadata: metadata,
        cancelToken: cancelToken,
      ).listen(
        (event) {
          if (event.type == AiStreamEventType.token) {
            completeFirstToken();
          }
          if (!controller.isClosed) {
            controller.add(event);
          }
        },
        onError: (Object error) {
          addStreamError(error);
          closeController();
        },
        onDone: () {
          closeController();
        },
      );
    }

    controller = StreamController<AiStreamEvent>(
      onListen: () {
        firstTokenTimer = Timer(_firstTokenTimeout, () {
          if (!receivedFirstToken) {
            addStreamError(const AppException(
              type: AppErrorType.timeout,
              message: 'AI response timed out. Please try again later.',
            ));
            closeController();
          }
        });
        overallTimer = Timer(_sseTimeout, () {
          addStreamError(const AppException(
            type: AppErrorType.timeout,
            message: 'AI response took too long and was stopped.',
          ));
          closeController();
        });
        start();
      },
      onCancel: () async {
        cancelToken?.cancel();
        await stop();
      },
    );

    return controller.stream;
  }

  Stream<AiStreamEvent> _streamWithAuthRetry({
    required String message,
    String? sessionKey,
    Map<String, Object?> metadata = const {},
    CancelToken? cancelToken,
    bool isRetry = false,
  }) async* {
    if (cancelToken?.isCanceled ?? false) {
      return;
    }

    final client = _clientFactory();
    cancelToken?._onCancel(client.close);

    try {
      final request = http.Request('POST', _streamUri())
        ..headers.addAll(await _headers())
        ..body = jsonEncode({
          'message': message,
          if (sessionKey != null && sessionKey.isNotEmpty)
            'sessionKey': sessionKey,
          if (metadata.isNotEmpty) 'metadata': metadata,
        });

      final response = await client.send(request);
      if (cancelToken?.isCanceled ?? false) {
        return;
      }

      if (response.statusCode == 401) {
        if (!isRetry && await _refreshJwtToken()) {
          yield* _streamWithAuthRetry(
            message: message,
            sessionKey: sessionKey,
            metadata: metadata,
            cancelToken: cancelToken,
            isRetry: true,
          );
          return;
        }
        await NavigationHelper.offAllNamed(Routes.login);
        throw const AppException(
          type: AppErrorType.unauthorized,
          message: 'Login expired. Please login again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 503) {
        final message = await _errorMessageFromResponse(
          response,
          fallback:
              'AI service is temporarily unavailable. Please try again later.',
        );
        throw AppException(
          type: AppErrorType.serviceUnavailable,
          message: message,
          statusCode: 503,
        );
      }

      if (response.statusCode >= 400) {
        final message = await _errorMessageFromResponse(
          response,
          fallback: 'AI stream request failed: ${response.statusCode}',
        );
        throw AppException.fromStatusCode(
          response.statusCode,
          message: message,
        );
      }

      yield* response.stream
          .transform(utf8.decoder)
          .transform(const SseStreamingParser());
    } finally {
      client.close();
    }
  }

  Future<bool> _refreshJwtToken() async {
    if (!Get.isRegistered<AuthService>()) {
      return false;
    }
    return Get.find<AuthService>().refreshJwtToken();
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

  Future<String> _errorMessageFromResponse(
    http.StreamedResponse response, {
    required String fallback,
  }) async {
    try {
      final body = await response.stream.bytesToString();
      if (body.trim().isEmpty) return fallback;
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Preserve the caller supplied fallback for malformed error bodies.
    }
    return fallback;
  }
}
