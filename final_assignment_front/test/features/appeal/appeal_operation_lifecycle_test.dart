import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/appeal_operation_lifecycle.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_appeal.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/utils/services/query_param.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final appeal = AppealRecordModel(
    offenseId: 7,
    driverId: 11,
    appellantName: 'Driver',
    appellantIdCard: '110101199001011234',
    appellantContact: '13800138000',
    appealReason: 'Incorrect location',
  );

  test(
    'transient retry keeps key and original body after modeled read loss',
    () async {
      final lifecycle = AppealOperationLifecycle(
        keyFactory: () => 'K-read-loss',
      );
      final keys = <String>[];
      final bodies = <AppealRecordModel>[];
      var calls = 0;

      Future<AppealRecordModel?> request(
        AppealRecordModel value,
        String key,
      ) async {
        calls++;
        keys.add(key);
        bodies.add(value);
        if (calls == 1) {
          throw TimeoutException('response read lost after commit');
        }
        return value;
      }

      final first = await lifecycle.submit(appeal: appeal, request: request);
      expect(first.outcome, AppealOperationOutcome.transientFailure);
      expect(lifecycle.state, AppealOperationState.retryable);

      final second = await lifecycle.submit(
        appeal: appeal.copyWith(appealReason: 'edited after timeout'),
        request: request,
      );
      expect(second.outcome, AppealOperationOutcome.success);
      expect(keys, ['K-read-loss', 'K-read-loss']);
      expect(bodies, [appeal, appeal]);
      expect(lifecycle.state, AppealOperationState.idle);
    },
  );

  test('pending calls coalesce and issue one request', () async {
    final lifecycle = AppealOperationLifecycle(keyFactory: () => 'K-pending');
    final response = Completer<AppealRecordModel?>();
    var calls = 0;

    Future<AppealRecordModel?> request(AppealRecordModel value, String key) {
      calls++;
      return response.future;
    }

    final first = lifecycle.submit(appeal: appeal, request: request);
    final second = lifecycle.submit(
      appeal: appeal.copyWith(appealReason: 'second tap'),
      request: request,
    );
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    expect(lifecycle.state, AppealOperationState.pending);

    response.complete(appeal);
    final results = await Future.wait([first, second]);
    expect(
      results.map((result) => result.outcome),
      everyElement(AppealOperationOutcome.success),
    );
    expect(lifecycle.state, AppealOperationState.idle);
  });

  test('nullable HTTP 208 is a terminal processed duplicate', () async {
    final client = _CapturingApiClient([
      () => http.Response(jsonEncode({'success': true, 'data': null}), 208),
    ]);
    final api = AppealManagementControllerApi(client);
    final lifecycle = AppealOperationLifecycle(keyFactory: () => 'K-208');

    final result = await lifecycle.submit(
      appeal: appeal,
      request: (value, key) =>
          api.createAppeal(appealRecord: value, idempotencyKey: key),
    );

    expect(result.outcome, AppealOperationOutcome.processedDuplicate);
    expect(result.appeal, isNull);
    expect(client.keys, ['K-208']);
    expect(lifecycle.state, AppealOperationState.idle);
  });

  test(
    'modeled response loss preserves the captured API header and body',
    () async {
      final client = _CapturingApiClient([
        () => throw TimeoutException('modeled response read loss'),
        () => http.Response(
              jsonEncode({'success': true, 'data': appeal.toJson()}),
              201,
            ),
      ]);
      final api = AppealManagementControllerApi(client);
      final lifecycle = AppealOperationLifecycle(keyFactory: () => 'K-header');

      Future<AppealRecordModel?> request(AppealRecordModel value, String key) {
        return api.createAppeal(appealRecord: value, idempotencyKey: key);
      }

      final first = await lifecycle.submit(appeal: appeal, request: request);
      expect(first.outcome, AppealOperationOutcome.transientFailure);
      final second = await lifecycle.submit(
        appeal: appeal.copyWith(appealReason: 'must not replace stored body'),
        request: request,
      );

      expect(second.outcome, AppealOperationOutcome.success);
      expect(client.keys, ['K-header', 'K-header']);
      expect(client.bodies, [appeal.toJson(), appeal.toJson()]);
    },
  );

  test(
    'terminal validation releases the key and next operation rotates it',
    () async {
      final keys = <String>[];
      var nextKey = 0;
      final lifecycle = AppealOperationLifecycle(
        keyFactory: () => 'K-${++nextKey}',
      );

      final validation = await lifecycle.submit(
        appeal: appeal,
        request: (value, key) async {
          keys.add(key);
          throw const AppException(
            type: AppErrorType.validationError,
            message: 'invalid appeal',
            statusCode: 422,
          );
        },
      );
      expect(validation.outcome, AppealOperationOutcome.validationFailure);
      expect(lifecycle.key, isNull);

      final success = await lifecycle.submit(
        appeal: appeal,
        request: (value, key) async {
          keys.add(key);
          return value;
        },
      );
      expect(success.outcome, AppealOperationOutcome.success);
      expect(keys, ['K-1', 'K-2']);
    },
  );

  test(
    'cancel invalidates an in-flight request and clears operation state',
    () async {
      final lifecycle = AppealOperationLifecycle(keyFactory: () => 'K-cancel');
      final response = Completer<AppealRecordModel?>();
      final pending = lifecycle.submit(
        appeal: appeal,
        request: (value, key) => response.future,
      );

      lifecycle.cancel();
      expect(lifecycle.state, AppealOperationState.idle);
      response.complete(appeal);
      expect((await pending).outcome, AppealOperationOutcome.cancelled);
    },
  );

  testWidgets('a pending submit button stays single-flight', (tester) async {
    final lifecycle = AppealOperationLifecycle(keyFactory: () => 'K-widget');
    final response = Completer<AppealRecordModel?>();
    var calls = 0;

    await tester.pumpWidget(
      _SubmitHarness(
        lifecycle: lifecycle,
        appeal: appeal,
        request: (value, key) {
          calls++;
          return response.future;
        },
      ),
    );

    final button = find.byType(ElevatedButton);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(lifecycle.state, AppealOperationState.pending);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    response.complete(appeal);
    await tester.pump();
    await tester.pump();
    expect(lifecycle.state, AppealOperationState.idle);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });

  testWidgets('barrier dismissal releases a retryable dialog operation', (
    tester,
  ) async {
    final lifecycle = await _retryableLifecycle(appeal, 'K-barrier');
    await tester.pumpWidget(_DialogHarness(lifecycle: lifecycle));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Appeal dialog'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text('Appeal dialog'), findsNothing);
    expect(lifecycle.state, AppealOperationState.idle);
  });

  testWidgets('system back releases a retryable dialog operation', (
    tester,
  ) async {
    final lifecycle = await _retryableLifecycle(appeal, 'K-back');
    await tester.pumpWidget(_DialogHarness(lifecycle: lifecycle));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Appeal dialog'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Appeal dialog'), findsNothing);
    expect(lifecycle.state, AppealOperationState.idle);
  });
}

Future<AppealOperationLifecycle> _retryableLifecycle(
  AppealRecordModel appeal,
  String key,
) async {
  final lifecycle = AppealOperationLifecycle(keyFactory: () => key);
  final result = await lifecycle.submit(
    appeal: appeal,
    request: (value, operationKey) async {
      throw TimeoutException('retryable');
    },
  );
  expect(result.outcome, AppealOperationOutcome.transientFailure);
  expect(lifecycle.state, AppealOperationState.retryable);
  return lifecycle;
}

class _CapturingApiClient extends ApiClient {
  _CapturingApiClient(this._responses)
      : super(client: MockClient((request) async => http.Response('', 500)));

  final List<FutureOr<http.Response> Function()> _responses;
  final List<String?> keys = [];
  final List<Object?> bodies = [];

  @override
  Future<http.Response> invokeAPI(
    String path,
    String method,
    Iterable<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? nullableContentType,
    List<String> authNames, {
    Set<int> passThroughStatusCodes = const {},
    bool isRetry = false,
  }) async {
    keys.add(headerParams['Idempotency-Key']);
    bodies.add(body);
    return await _responses.removeAt(0)();
  }
}

class _SubmitHarness extends StatefulWidget {
  const _SubmitHarness({
    required this.lifecycle,
    required this.appeal,
    required this.request,
  });

  final AppealOperationLifecycle lifecycle;
  final AppealRecordModel appeal;
  final AppealSubmitRequest request;

  @override
  State<_SubmitHarness> createState() => _SubmitHarnessState();
}

class _SubmitHarnessState extends State<_SubmitHarness> {
  bool _pending = false;

  void _submit() {
    if (_pending) return;
    setState(() => _pending = true);
    widget.lifecycle
        .submit(appeal: widget.appeal, request: widget.request)
        .then((_) {
      if (mounted) setState(() => _pending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: _pending ? null : _submit,
          child: Text(_pending ? 'Submitting' : 'Submit'),
        ),
      ),
    );
  }
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({required this.lifecycle});

  final AppealOperationLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showAppealOperationDialog<void>(
              context: context,
              lifecycle: lifecycle,
              builder: (context) => const Dialog(child: Text('Appeal dialog')),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }
}
