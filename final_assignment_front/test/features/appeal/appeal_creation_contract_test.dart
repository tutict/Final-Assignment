import 'dart:convert';

import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await AuthTokenStore.instance.clearAll();
  });

  test('authenticated duplicate creation accepts 208 null with the same key',
      () async {
    const retryKey = 'appeal-cross-layer-key';
    await AuthTokenStore.instance.setJwtToken('test-bearer-token');
    late http.Request observedRequest;
    final client = MockClient((request) async {
      observedRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'data': null}),
        208,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AppealManagementControllerApi(
      ApiClient(basePath: 'http://localhost', client: client),
    );

    final result = await api.createAppeal(
      appealRecord: _appeal(),
      idempotencyKey: retryKey,
    );

    expect(result, isNull);
    expect(observedRequest.method, 'POST');
    expect(observedRequest.url.path, '/api/appeals');
    expect(observedRequest.headers['Idempotency-Key'], retryKey);
    expect(
        observedRequest.headers['Authorization'], 'Bearer test-bearer-token');
  });

  test(
      'transient failure keeps the key and concurrent submit shares one request',
      () async {
    final keys = <String>[];
    var attempts = 0;
    final operation = AppealCreationOperation.withTransport(
      keyFactory: () => 'retry-key',
      send: (appeal, key) async {
        attempts++;
        keys.add(key);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (attempts == 1) {
          throw const AppException(
            type: AppErrorType.network,
            message: 'offline',
          );
        }
        return _appeal();
      },
    );

    final first = operation.submit(_appeal());
    final second = operation.submit(_appeal());
    expect(identical(first, second), isTrue);
    await expectLater(first, throwsA(isA<AppException>()));
    expect(operation.retryKey, 'retry-key');

    await operation.submit(_appeal());
    expect(attempts, 2);
    expect(keys, ['retry-key', 'retry-key']);
    expect(operation.retryKey, isNull);
  });

  test('terminal validation failure releases the retry key', () async {
    final operation = AppealCreationOperation.withTransport(
      keyFactory: () => 'validation-key',
      send: (appeal, key) async {
        throw const AppException(
          type: AppErrorType.validationError,
          message: 'invalid',
        );
      },
    );

    await expectLater(
        operation.submit(_appeal()), throwsA(isA<AppException>()));
    expect(operation.retryKey, isNull);
  });

  test('duplicate success releases once and the next operation gets a new key',
      () async {
    final generatedKeys = <String>['K1', 'K2'].iterator;
    final observedKeys = <String>[];
    var attempts = 0;
    final operation = AppealCreationOperation.withTransport(
      keyFactory: () {
        generatedKeys.moveNext();
        return generatedKeys.current;
      },
      send: (appeal, key) async {
        attempts++;
        observedKeys.add(key);
        return attempts == 1 ? null : _appeal();
      },
    );

    expect(await operation.submit(_appeal()), isNull);
    expect(attempts, 1);
    expect(operation.retryKey, isNull);

    expect(await operation.submit(_appeal()), isNotNull);
    expect(observedKeys, ['K1', 'K2']);
    expect(operation.retryKey, isNull);
  });

  test('cancel releases a retained transient key', () async {
    final generatedKeys = <String>['K1', 'K2'].iterator;
    final observedKeys = <String>[];
    var attempts = 0;
    final operation = AppealCreationOperation.withTransport(
      keyFactory: () {
        generatedKeys.moveNext();
        return generatedKeys.current;
      },
      send: (appeal, key) async {
        attempts++;
        observedKeys.add(key);
        if (attempts == 1) {
          throw const AppException(
            type: AppErrorType.timeout,
            message: 'timeout',
          );
        }
        return _appeal();
      },
    );

    await expectLater(
        operation.submit(_appeal()), throwsA(isA<AppException>()));
    operation.cancel();
    await operation.submit(_appeal());

    expect(observedKeys, ['K1', 'K2']);
  });
}

AppealRecordModel _appeal() => AppealRecordModel(
      offenseId: 41,
      appellantName: 'Contract User',
      appellantIdCard: '110101199001011234',
      appellantContact: '13800138000',
      appealReason: 'The recorded offense does not match the observed event.',
      appealTime: DateTime.utc(2026, 7, 23, 9),
    );
