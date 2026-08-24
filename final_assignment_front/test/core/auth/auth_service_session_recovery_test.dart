import 'dart:convert';

import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session-recovery contract tests for [AuthService] against the Spring
/// refresh contract (EXP-005 Change Contract):
/// terminal rejection (400/401/403, missing refresh token) destroys the
/// local session; transient failures (429/5xx/network/parse) must not.
///
/// Uses only public API so the transient cases run RED against the
/// pre-change implementation.
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

  Future<void> seedSession({
    required String jwt,
    String? refreshToken = 'seed-refresh-token',
  }) async {
    await AuthTokenStore.instance.setJwtToken(jwt);
    await AuthTokenStore.instance.setRefreshToken(refreshToken);
  }

  setUp(() async {
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });

  group('transient refresh failures preserve the session (RED pre-change)', () {
    test('429 during proactive refresh keeps a still-valid session', () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 2));
      await seedSession(jwt: jwt);
      var refreshCalls = 0;
      final service = AuthService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/refresh') {
            refreshCalls++;
            return http.Response(
              jsonEncode({
                'success': false,
                'errorCode': 'LOGIN_RATE_LIMITED',
                'message': 'throttled',
                'retryAfterSeconds': 30,
              }),
              429,
            );
          }
          fail('unexpected request: ${request.url}');
        }),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isTrue,
          reason: 'access token is still valid; a transient 429 on refresh '
              'must not invalidate the session');
      expect(refreshCalls, 1);
      expect(await AuthTokenStore.instance.getJwtToken(), jwt,
          reason: 'access token must be preserved');
      expect(
          await AuthTokenStore.instance.getRefreshToken(), 'seed-refresh-token',
          reason: 'refresh token must be preserved');
    });

    test('network failure during proactive refresh keeps a still-valid session',
        () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 2));
      await seedSession(jwt: jwt);
      final service = AuthService(
        client: MockClient((request) async {
          throw http.ClientException('network unreachable', request.url);
        }),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isTrue);
      expect(await AuthTokenStore.instance.getJwtToken(), jwt);
      expect(await AuthTokenStore.instance.getRefreshToken(),
          'seed-refresh-token');
    });

    test('5xx with a hard-expired access token preserves the refresh token',
        () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: -1));
      await seedSession(jwt: jwt);
      final service = AuthService(
        client: MockClient((request) async =>
            http.Response(jsonEncode({'error': 'boom'}), 503)),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isFalse,
          reason: 'expired access token cannot be used right now');
      expect(await AuthTokenStore.instance.getJwtToken(), jwt,
          reason: 'transient failure must not clear the stored access token');
      expect(
        await AuthTokenStore.instance.getRefreshToken(),
        'seed-refresh-token',
        reason: 'a transient 503 must not delete a refresh token the server '
            'still honors — the next attempt may recover the session',
      );
    });

    test('200 with an unusable body is transient, not terminal', () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 2));
      await seedSession(jwt: jwt);
      final service = AuthService(
        client: MockClient((request) async =>
            http.Response(jsonEncode({'success': true}), 200)),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isTrue);
      expect(await AuthTokenStore.instance.getJwtToken(), jwt);
      expect(await AuthTokenStore.instance.getRefreshToken(),
          'seed-refresh-token');
    });
  });

  group('terminal refresh rejection (characterization)', () {
    test('401 rejection clears the stored session', () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 2));
      await seedSession(jwt: jwt);
      final service = AuthService(
        client: MockClient((request) async => http.Response(
            jsonEncode({
              'success': false,
              'errorCode': 'UNAUTHORIZED',
              'message': 'Invalid refresh token',
            }),
            401)),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isFalse);
      expect(await AuthTokenStore.instance.getJwtToken(), isNull,
          reason: 'server explicitly rejected the refresh token');
      expect(await AuthTokenStore.instance.getRefreshToken(), isNull);
    });

    test('expired token without a refresh token is invalid and cleaned up',
        () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: -1));
      await seedSession(jwt: jwt, refreshToken: null);
      final service = AuthService(
        client: MockClient(
            (request) async => fail('no HTTP call expected without a token')),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isFalse);
      expect(await AuthTokenStore.instance.getJwtToken(), isNull,
          reason: 'an unrecoverable session must not leave a stale '
              'access token behind');
    });
  });

  group('preserved session behaviors (characterization)', () {
    test('successful refresh rotates and persists both tokens', () async {
      final oldJwt = buildJwt(expiresIn: const Duration(minutes: 2));
      final newJwt = buildJwt(expiresIn: const Duration(minutes: 30));
      await seedSession(jwt: oldJwt);
      final service = AuthService(
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refreshToken'], 'seed-refresh-token');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': newJwt,
                'refreshToken': 'rotated-refresh-token',
                'expiresIn': 3600,
              },
            }),
            200,
          );
        }),
      );

      final valid = await service.ensureValidSession();

      expect(valid, isTrue);
      expect(await AuthTokenStore.instance.getJwtToken(), newJwt);
      expect(await AuthTokenStore.instance.getRefreshToken(),
          'rotated-refresh-token');
    });

    test('concurrent refresh calls share a single HTTP request', () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 2));
      final newJwt = buildJwt(expiresIn: const Duration(minutes: 30));
      await seedSession(jwt: jwt);
      var refreshCalls = 0;
      final service = AuthService(
        client: MockClient((request) async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'accessToken': newJwt, 'refreshToken': 'r2'},
            }),
            200,
          );
        }),
      );

      final results = await Future.wait([
        service.refreshJwtToken(),
        service.refreshJwtToken(),
        service.refreshJwtToken(),
      ]);

      expect(results, everyElement(isTrue));
      expect(refreshCalls, 1,
          reason: 'refresh must be single-flight under concurrency');
    });

    test('logout clears local session even when the logout API fails',
        () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 30));
      await seedSession(jwt: jwt);
      final service = AuthService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/logout');
          return http.Response('server exploded', 500);
        }),
      );

      await service.logout();

      expect(await AuthTokenStore.instance.getJwtToken(), isNull);
      expect(await AuthTokenStore.instance.getRefreshToken(), isNull);
    });

    test('403 handling does not clear the session', () async {
      final jwt = buildJwt(expiresIn: const Duration(minutes: 30));
      await seedSession(jwt: jwt);
      final service = AuthService(client: MockClient((request) async {
        fail('no HTTP call expected');
      }));

      await service.handleForbidden(source: 'test', message: 'denied');

      expect(await AuthTokenStore.instance.getJwtToken(), jwt);
      expect(await AuthTokenStore.instance.getRefreshToken(),
          'seed-refresh-token');
    });
  });
}
