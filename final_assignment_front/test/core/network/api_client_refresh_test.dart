import 'dart:convert';

import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Behavior of [ApiClient] when a bearer request hits 401 and the refresh
/// attempt itself fails transiently: the session must survive, and the caller
/// must see a retryable error instead of a forced logout.
class _RecordingAuthService extends AuthService {
  _RecordingAuthService({super.client});

  int unauthorizedCalls = 0;

  @override
  Future<void> handleUnauthorized({String? source}) async {
    unauthorizedCalls++;
    await clearTokens();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, String>{};

  String encodeSegment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  String buildJwt({required Duration expiresIn}) {
    final now = DateTime.now();
    final header = encodeSegment({'alg': 'HS256', 'typ': 'JWT'});
    final payload = encodeSegment({
      'sub': 'testuser',
      'roles': 'USER',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(expiresIn).millisecondsSinceEpoch ~/ 1000,
    });
    return '$header.$payload.test-signature';
  }

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    secureStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>?;
      final key = args?['key'] as String?;
      switch (call.method) {
        case 'read':
          return secureStore[key];
        case 'write':
          secureStore[key!] = args!['value'] as String;
          return null;
        case 'delete':
          secureStore.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.of(secureStore);
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          return secureStore.containsKey(key);
      }
      return null;
    });
    await AuthTokenStore.instance.clearAll();
  });

  tearDown(() {
    Get.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });

  test('401 with a transient refresh failure keeps the session and throws a '
      'retryable network error', () async {
    final jwt = buildJwt(expiresIn: const Duration(minutes: 30));
    await AuthTokenStore.instance.setJwtToken(jwt);
    await AuthTokenStore.instance.setRefreshToken('seed-refresh-token');

    final authService = AuthService(
      client: MockClient((request) async {
        throw http.ClientException('refresh endpoint unreachable', request.url);
      }),
    );
    Get.put<AuthService>(authService);

    final client = ApiClient(
      basePath: 'https://api.test',
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'unauthorized'}),
            401,
          )),
    );

    await expectLater(
      client.invokeAPI(
        '/api/vehicles',
        'GET',
        const [],
        null,
        <String, String>{},
        <String, String>{},
        null,
        ['bearerAuth'],
      ),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.network)),
    );

    expect(await AuthTokenStore.instance.getJwtToken(), jwt,
        reason: 'a transient refresh failure must not clear the access token');
    expect(await AuthTokenStore.instance.getRefreshToken(), 'seed-refresh-token',
        reason: 'the server may still honor this refresh token later');
  });

  test('an expired access token is never sent when the refresh is transient',
      () async {
    final expiredJwt = buildJwt(expiresIn: const Duration(minutes: -1));
    await AuthTokenStore.instance.setJwtToken(expiredJwt);
    await AuthTokenStore.instance.setRefreshToken('seed-refresh-token');

    var refreshCalls = 0;
    final authService = AuthService(
      client: MockClient((request) async {
        refreshCalls++;
        throw http.ClientException('refresh endpoint unreachable', request.url);
      }),
    );
    Get.put<AuthService>(authService);

    final client = ApiClient(
      basePath: 'https://api.test',
      client: MockClient((request) async {
        fail('an expired bearer token must not be sent to ${request.url}');
      }),
    );

    await expectLater(
      client.invokeAPI(
        '/api/vehicles',
        'GET',
        const [],
        null,
        <String, String>{},
        <String, String>{},
        null,
        ['bearerAuth'],
      ),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.network)),
    );

    expect(refreshCalls, 1);
    expect(await AuthTokenStore.instance.getJwtToken(), expiredJwt,
        reason: 'the session is recoverable once the network returns');
    expect(await AuthTokenStore.instance.getRefreshToken(), 'seed-refresh-token');
  });

  test('401 with a rejected refresh clears the session and throws unauthorized',
      () async {
    final jwt = buildJwt(expiresIn: const Duration(minutes: 30));
    await AuthTokenStore.instance.setJwtToken(jwt);
    await AuthTokenStore.instance.setRefreshToken('seed-refresh-token');

    final authService = _RecordingAuthService(
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'Invalid refresh token'}),
            401,
          )),
    );
    Get.put<AuthService>(authService);

    final client = ApiClient(
      basePath: 'https://api.test',
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'unauthorized'}),
            401,
          )),
    );

    await expectLater(
      client.invokeAPI(
        '/api/vehicles',
        'GET',
        const [],
        null,
        <String, String>{},
        <String, String>{},
        null,
        ['bearerAuth'],
      ),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.unauthorized)),
    );

    expect(authService.unauthorizedCalls, 1);
    expect(await AuthTokenStore.instance.getJwtToken(), isNull);
    expect(await AuthTokenStore.instance.getRefreshToken(), isNull);
  });
}
