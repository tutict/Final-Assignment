import 'dart:async';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/network/base_api_client.dart';
import 'package:final_assignment_front/features/appeal/appeal_submission_coordinator.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const appeal = AppealRecordModel(offenseId: 7);
  const crossLayerFixtureKey = 'EXP006-CROSS-LAYER-KEY-0001';

  test('shares a pending request and key across duplicate triggers', () async {
    final gate = Completer<AppealRecordModel?>();
    final keys = <String>[];
    final coordinator = AppealSubmissionCoordinator(
      keyFactory: () => 'key-1',
      createAppeal: (_, key) {
        keys.add(key);
        return gate.future;
      },
    );

    final first = coordinator.submit(appeal);
    final second = coordinator.submit(appeal);
    expect(identical(first, second), isTrue);
    expect(keys, ['key-1']);

    gate.complete(appeal);
    expect((await first).succeeded, isTrue);
    expect(coordinator.activeIdempotencyKey, isNull);
  });

  test(
    'keeps a transient failure key for retry, then rotates after success',
    () async {
      var calls = 0;
      final keys = <String>[];
      var keyNumber = 0;
      final coordinator = AppealSubmissionCoordinator(
        keyFactory: () => 'key-${++keyNumber}',
        createAppeal: (_, key) {
          calls++;
          keys.add(key);
          if (calls == 1) {
            throw const AppException(
              type: AppErrorType.timeout,
              message: 'temporary',
            );
          }
          return Future.value(appeal);
        },
      );

      expect((await coordinator.submit(appeal)).retryable, isTrue);
      expect(coordinator.activeIdempotencyKey, 'key-1');
      expect((await coordinator.submit(appeal)).succeeded, isTrue);
      expect(keys, ['key-1', 'key-1']);

      expect((await coordinator.submit(appeal)).succeeded, isTrue);
      expect(keys, ['key-1', 'key-1', 'key-2']);
    },
  );

  test('models a lost response retry and treats 208 null as terminal success',
      () async {
    var calls = 0;
    final keys = <String>[];
    final coordinator = AppealSubmissionCoordinator(
      keyFactory: () => crossLayerFixtureKey,
      createAppeal: (_, key) {
        calls++;
        keys.add(key);
        if (calls == 1) {
          return Future<AppealRecordModel?>.error(
            const AppException(
              type: AppErrorType.network,
              message: 'response lost after server accepted request',
            ),
          );
        }
        return Future.value(
          _ProbeApiClient().parseNullableResponse<AppealRecordModel>(
            http.Response(
              '{"success":true,"data":null}',
              208,
              headers: {'content-type': 'application/json'},
            ),
            AppealRecordModel.fromJson,
          ),
        );
      },
    );

    final first = await coordinator.submit(appeal);
    expect(first.retryable, isTrue);
    expect(coordinator.activeIdempotencyKey, crossLayerFixtureKey);

    final second = await coordinator.submit(appeal);
    expect(second.succeeded, isTrue);
    expect(second.wasAlreadyProcessed, isTrue);
    expect(coordinator.activeIdempotencyKey, isNull);
    expect(coordinator.isPending, isFalse);
    expect(keys, [crossLayerFixtureKey, crossLayerFixtureKey]);
    expect(calls, 2);
  });

  test('terminal failure and cancellation release the key', () async {
    final pending = Completer<AppealRecordModel?>();
    final replacementGate = Completer<AppealRecordModel?>();
    var keyNumber = 0;
    final keys = <String>[];
    final coordinator = AppealSubmissionCoordinator(
      keyFactory: () => 'key-${++keyNumber}',
      createAppeal: (_, key) {
        keys.add(key);
        return key == 'key-1' ? pending.future : replacementGate.future;
      },
    );

    final cancelled = coordinator.submit(appeal);
    expect(coordinator.activeIdempotencyKey, 'key-1');
    coordinator.cancel();
    expect(coordinator.activeIdempotencyKey, isNull);

    final replacement = coordinator.submit(appeal);
    expect(coordinator.activeIdempotencyKey, 'key-2');
    pending.complete(appeal);
    expect((await cancelled).cancelled, isTrue);
    replacementGate.complete(appeal);
    expect((await replacement).succeeded, isTrue);

    final terminal = AppealSubmissionCoordinator(
      keyFactory: () => 'terminal-key',
      createAppeal: (_, __) => Future<AppealRecordModel?>.error(
        const AppException(
          type: AppErrorType.validationError,
          message: 'invalid',
        ),
      ),
    );
    expect((await terminal.submit(appeal)).retryable, isFalse);
    expect(terminal.activeIdempotencyKey, isNull);
  });

  test('208 success with null data is a nullable success, not a TypeError', () {
    final response = http.Response(
      '{"success":true,"data":null}',
      208,
      headers: {'content-type': 'application/json'},
    );

    final parsed = _ProbeApiClient().parseNullableResponse<AppealRecordModel>(
      response,
      AppealRecordModel.fromJson,
    );

    expect(parsed, isNull);
  });
}

class _ProbeApiClient with BaseApiClient {
  @override
  ApiClient get apiClient => ApiClient();
}
