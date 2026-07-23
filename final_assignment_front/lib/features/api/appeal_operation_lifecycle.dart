import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:uuid/uuid.dart';

enum AppealOperationOutcome {
  success,
  processedDuplicate,
  validationFailure,
  transientFailure,
  terminalFailure,
  cancelled,
}

enum AppealOperationState { idle, pending, retryable }

class AppealOperationResult {
  const AppealOperationResult({required this.outcome, this.appeal, this.error});

  final AppealOperationOutcome outcome;
  final AppealRecordModel? appeal;
  final Object? error;

  bool get isSuccessful =>
      outcome == AppealOperationOutcome.success ||
      outcome == AppealOperationOutcome.processedDuplicate;
}

typedef AppealSubmitRequest = Future<AppealRecordModel?> Function(
  AppealRecordModel appeal,
  String idempotencyKey,
);

/// Owns the key and request body for one logical appeal operation.
///
/// A transient failure keeps both values for the next call. Concurrent calls
/// share the same future, so a second tap cannot issue another request.
class AppealOperationLifecycle {
  AppealOperationLifecycle({String Function()? keyFactory})
      : _keyFactory = keyFactory ?? generateKey;

  static const Uuid _uuid = Uuid();

  final String Function() _keyFactory;
  String? _key;
  String? _operationSignature;
  AppealRecordModel? _appeal;
  Future<AppealOperationResult>? _pending;
  int _generation = 0;

  static String generateKey() => _uuid.v4();

  AppealOperationState get state {
    if (_pending != null) return AppealOperationState.pending;
    if (_key != null) return AppealOperationState.retryable;
    return AppealOperationState.idle;
  }

  String? get key => _key;

  AppealRecordModel? get appeal => _appeal;

  String? get operationSignature => _operationSignature;

  bool get isPending => _pending != null;

  /// Submits or retries one operation. A pending call is coalesced.
  Future<AppealOperationResult> submit({
    required AppealRecordModel appeal,
    required AppealSubmitRequest request,
  }) {
    final pending = _pending;
    if (pending != null) return pending;

    if (_key == null) {
      _key = _keyFactory();
      _appeal = appeal;
      _operationSignature = fingerprintFor(appeal);
    }

    final operationAppeal = _appeal!;
    final operationKey = _key!;
    final generation = ++_generation;
    late final Future<AppealOperationResult> future;
    future = _execute(
      appeal: operationAppeal,
      key: operationKey,
      generation: generation,
      request: request,
    );
    _pending = future;
    future.whenComplete(() {
      if (identical(_pending, future)) {
        _pending = null;
      }
    });
    return future;
  }

  Future<AppealOperationResult> _execute({
    required AppealRecordModel appeal,
    required String key,
    required int generation,
    required AppealSubmitRequest request,
  }) async {
    try {
      final created = await request(appeal, key);
      if (generation != _generation) {
        return const AppealOperationResult(
          outcome: AppealOperationOutcome.cancelled,
        );
      }
      final outcome = created == null
          ? AppealOperationOutcome.processedDuplicate
          : AppealOperationOutcome.success;
      _complete(outcome);
      return AppealOperationResult(outcome: outcome, appeal: created);
    } catch (error) {
      final outcome = classifyError(error);
      if (generation == _generation) {
        _complete(outcome);
        return AppealOperationResult(outcome: outcome, error: error);
      }
      return const AppealOperationResult(
        outcome: AppealOperationOutcome.cancelled,
      );
    }
  }

  /// Releases terminal outcomes while retaining key/body for transient ones.
  void _complete(AppealOperationOutcome outcome) {
    if (outcome == AppealOperationOutcome.transientFailure) {
      return;
    }
    _release();
  }

  /// Cancels an idle/retryable operation or invalidates an in-flight request.
  void cancel() {
    _generation++;
    _release();
    _pending = null;
  }

  AppealOperationOutcome classifyError(Object error) {
    final exception = AppException.fromError(error);
    switch (exception.type) {
      case AppErrorType.network:
      case AppErrorType.timeout:
      case AppErrorType.serviceUnavailable:
      case AppErrorType.serverError:
        return AppealOperationOutcome.transientFailure;
      case AppErrorType.validationError:
        return AppealOperationOutcome.validationFailure;
      case AppErrorType.duplicate:
        return AppealOperationOutcome.processedDuplicate;
      case AppErrorType.unauthorized:
      case AppErrorType.forbidden:
      case AppErrorType.notFound:
      case AppErrorType.conflict:
      case AppErrorType.businessError:
      case AppErrorType.unknown:
        return AppealOperationOutcome.terminalFailure;
    }
  }

  static String fingerprintFor(AppealRecordModel appeal) {
    return jsonEncode(<String, Object?>{
      'offenseId': appeal.offenseId,
      'driverId': appeal.driverId,
      'appellantName': appeal.appellantName,
      'appellantIdCard': appeal.appellantIdCard,
      'appellantContact': appeal.appellantContact,
      'appellantEmail': appeal.appellantEmail,
      'appellantAddress': appeal.appellantAddress,
      'appealType': appeal.appealType,
      'appealReason': appeal.appealReason,
      'evidenceDescription': appeal.evidenceDescription,
      'evidenceUrls': appeal.evidenceUrls,
    });
  }

  void _release() {
    _key = null;
    _operationSignature = null;
    _appeal = null;
  }
}
