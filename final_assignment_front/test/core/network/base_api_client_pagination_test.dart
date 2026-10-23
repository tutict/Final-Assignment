import 'dart:convert';

import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/network/base_api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [BaseApiClient.requestAllPages] must collect every server page: the
/// generated `requestList` only reads the first `content` page, so manager
/// lists silently showed at most 20 rows.
class _ProbeApi with BaseApiClient {
  _ProbeApi(this.apiClient);

  @override
  final ApiClient apiClient;
}

Map<String, dynamic> _pageBody({
  required List<Map<String, dynamic>> rows,
  required int total,
  required int page,
  required int size,
}) {
  return {
    'success': true,
    'data': {
      'content': rows,
      'total': total,
      'page': page,
      'size': size,
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, String>{};

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

  test('collects every page even when the server caps the page size',
      () async {
    final all = List.generate(45, (index) => {'id': index});
    var calls = 0;
    final api = _ProbeApi(
      ApiClient(
        basePath: 'https://api.test',
        client: MockClient((request) async {
          calls++;
          final page = int.parse(request.url.queryParameters['page'] ?? '0');
          const serverSize = 20;
          final from = (page * serverSize).clamp(0, all.length);
          final to = (from + serverSize).clamp(0, all.length);
          return http.Response(
            jsonEncode(_pageBody(
              rows: all.sublist(from, to),
              total: all.length,
              page: page,
              size: serverSize,
            )),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final rows = await api.requestAllPages<Map<String, dynamic>>(
      '/api/vehicles',
      (json) => json,
    );

    expect(rows, hasLength(45));
    expect(rows.first['id'], 0);
    expect(rows.last['id'], 44);
    expect(calls, 3, reason: '20 + 20 + 5 rows over three pages');
  });

  test('returns a bare array endpoint untouched', () async {
    final api = _ProbeApi(
      ApiClient(
        basePath: 'https://api.test',
        client: MockClient((request) async => http.Response(
              jsonEncode([
                {'id': 1},
                {'id': 2},
              ]),
              200,
              headers: const {'content-type': 'application/json'},
            )),
      ),
    );

    final rows = await api.requestAllPages<Map<String, dynamic>>(
      '/api/logs/login',
      (json) => json,
    );

    expect(rows, hasLength(2));
  });

  test('stops when a page comes back empty even if total claims more',
      () async {
    final api = _ProbeApi(
      ApiClient(
        basePath: 'https://api.test',
        client: MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page'] ?? '0');
          return http.Response(
            jsonEncode(_pageBody(
              rows: page == 0
                  ? List.generate(20, (index) => {'id': index})
                  : const [],
              total: 1000,
              page: page,
              size: 20,
            )),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final rows = await api.requestAllPages<Map<String, dynamic>>(
      '/api/offenses',
      (json) => json,
    );

    expect(rows, hasLength(20));
  });
}
