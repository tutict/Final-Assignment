import 'package:uuid/uuid.dart';

import '../../core/network/app_exception.dart';
import '../model/appeal_record.dart';

typedef AppealCreateCall = Future<AppealRecordModel?> Function(
  AppealRecordModel appeal,
  String idempotencyKey,
);

enum AppealSubmissionStatus {
  succeeded,
  retryableFailure,
  terminalFailure,
  cancelled,
}

class AppealSubmissionResult {
  const AppealSubmissionResult._({
    required this.status,
    this.appeal,
    this.error,
  });

  const AppealSubmissionResult.succeeded({AppealRecordModel? appeal})
      : this._(status: AppealSubmissionStatus.succeeded, appeal: appeal);

  const AppealSubmissionResult.failure({
    required AppealSubmissionStatus status,
    required AppException error,
  }) : this._(status: status, error: error);

  const AppealSubmissionResult.cancelled()
      : this._(status: AppealSubmissionStatus.cancelled);

  final AppealSubmissionStatus status;
  final AppealRecordModel? appeal;
  final AppException? error;

  bool get succeeded => status == AppealSubmissionStatus.succeeded;
  bool get retryable => status == AppealSubmissionStatus.retryableFailure;
  bool get cancelled => status == AppealSubmissionStatus.cancelled;

  /// The Spring duplicate contract returns HTTP 208 with a null data payload.
  bool get wasAlreadyProcessed => succeeded && appeal == null;
}

/// Owns one logical appeal operation from its first attempt through retry.
///
/// A pending call is shared by duplicate triggers. The key is retained only
/// for retryable/unknown outcomes, so a new operation cannot accidentally
/// reuse a completed, cancelled, or terminally invalidated key.
class AppealSubmissionCoordinator {
  AppealSubmissionCoordinator({
    required AppealCreateCall createAppeal,
    String Function()? keyFactory,
  })  : _createAppeal = createAppeal,
        _keyFactory = keyFactory ?? _newKey;

  final AppealCreateCall _createAppeal;
  final String Function() _keyFactory;

  String? _activeKey;
  Future<AppealSubmissionResult>? _inFlight;
  int _generation = 0;

  bool get isPending => _inFlight != null;
  String? get activeIdempotencyKey => _activeKey;

  Future<AppealSubmissionResult> submit(AppealRecordModel appeal) {
    final pending = _inFlight;
    if (pending != null) {
      return pending;
    }

    final key = _activeKey ??= _keyFactory();
    final generation = ++_generation;
    late final Future<AppealSubmissionResult> future;
    future = _run(appeal, key, generation).whenComplete(() {
      if (_generation == generation && identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    _inFlight = future;
    return future;
  }

  void cancel() {
    _generation++;
    _activeKey = null;
    _inFlight = null;
  }

  Future<AppealSubmissionResult> _run(
    AppealRecordModel appeal,
    String key,
    int generation,
  ) async {
    try {
      final created = await _createAppeal(appeal, key);
      if (_generation != generation) {
        return const AppealSubmissionResult.cancelled();
      }
      _activeKey = null;
      return AppealSubmissionResult.succeeded(appeal: created);
    } catch (error) {
      if (_generation != generation) {
        return const AppealSubmissionResult.cancelled();
      }
      final exception = AppException.fromError(error);
      if (exception.type == AppErrorType.duplicate) {
        _activeKey = null;
        return const AppealSubmissionResult.succeeded();
      }

      final retryable = _isRetryable(exception);
      if (!retryable) {
        _activeKey = null;
      }
      return AppealSubmissionResult.failure(
        status: retryable
            ? AppealSubmissionStatus.retryableFailure
            : AppealSubmissionStatus.terminalFailure,
        error: exception,
      );
    }
  }

  bool _isRetryable(AppException exception) {
    return switch (exception.type) {
      AppErrorType.network ||
      AppErrorType.timeout ||
      AppErrorType.serviceUnavailable ||
      AppErrorType.serverError ||
      AppErrorType.conflict ||
      AppErrorType.unknown =>
        true,
      _ => false,
    };
  }

  static String _newKey() => const Uuid().v4();
}
