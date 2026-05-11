import 'dart:developer' as developer;

import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/features/api/login_log_controller_api.dart';
import 'package:final_assignment_front/features/api/operation_log_controller_api.dart';
import 'package:final_assignment_front/features/api/system_logs_controller_api.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/shared/controllers/base_list_controller.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:get/get.dart';

class LogController extends BaseListController<Object> {
  LogController({
    LoginLogControllerApi? loginLogApi,
    OperationLogControllerApi? operationLogApi,
    SystemLogsControllerApi? systemLogsApi,
  })  : _loginLogApi = loginLogApi ?? LoginLogControllerApi(),
        _operationLogApi = operationLogApi ?? OperationLogControllerApi(),
        _systemLogsApi = systemLogsApi ?? SystemLogsControllerApi();

  final LoginLogControllerApi _loginLogApi;
  final OperationLogControllerApi _operationLogApi;
  final SystemLogsControllerApi _systemLogsApi;

  final RxList<LoginLog> loginLogs = <LoginLog>[].obs;
  final RxList<OperationLog> operationLogs = <OperationLog>[].obs;
  final RxMap<String, dynamic> systemOverview = <String, dynamic>{}.obs;
  final RxList<LoginLog> recentLoginLogs = <LoginLog>[].obs;
  final RxList<OperationLog> recentOperationLogs = <OperationLog>[].obs;

  @override
  Future<void> fetchData() async {}

  Future<void> fetchLoginLogs() async {
    await _load(() async {
      await _loginLogApi.initializeWithJwt();
      loginLogs.assignAll(await _loginLogApi.listLoginLogs());
    });
  }

  Future<void> fetchLoginLogsByUsername({
    required String username,
    int page = 1,
    int size = 20,
  }) async {
    await _load(() async {
      await _loginLogApi.initializeWithJwt();
      loginLogs.assignAll(
        await _loginLogApi.searchLoginLogsByUsername(
          username: username,
          page: page,
          size: size,
        ),
      );
    });
  }

  Future<void> fetchOperationLogs() async {
    await _load(() async {
      await _operationLogApi.initializeWithJwt();
      operationLogs.assignAll(await _operationLogApi.listOperationLogs());
    });
  }

  Future<void> fetchOperationLogsByUser({
    required int userId,
    int page = 1,
    int size = 20,
  }) async {
    await _load(() async {
      await _operationLogApi.initializeWithJwt();
      operationLogs.assignAll(
        await _operationLogApi.searchOperationLogsByUser(
          userId: userId,
          page: page,
          size: size,
        ),
      );
    });
  }

  Future<void> fetchOperationLogsByTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    int page = 1,
    int size = 20,
  }) async {
    await _load(() async {
      await _operationLogApi.initializeWithJwt();
      operationLogs.assignAll(
        await _operationLogApi.searchOperationLogsByTimeRange(
          startTime: startTime.toIso8601String(),
          endTime: endTime.toIso8601String(),
          page: page,
          size: size,
        ),
      );
    });
  }

  Future<void> fetchSystemLogDashboard({int recentLimit = 20}) async {
    await _load(() async {
      await _systemLogsApi.initializeWithJwt();
      final overview = await _systemLogsApi.getSystemLogsOverview();
      final login = await _systemLogsApi.listRecentLoginLogs(
        limit: recentLimit,
      );
      final operation = await _systemLogsApi.listRecentOperationLogs(
        limit: recentLimit,
      );

      systemOverview.assignAll(overview);
      recentLoginLogs.assignAll(login);
      recentOperationLogs.assignAll(operation);
    });
  }

  Future<void> refreshAll({int recentLimit = 20}) async {
    await _load(() async {
      await Future.wait([
        _loginLogApi.initializeWithJwt(),
        _operationLogApi.initializeWithJwt(),
        _systemLogsApi.initializeWithJwt(),
      ]);

      final results = await Future.wait<Object>([
        _loginLogApi.listLoginLogs(),
        _operationLogApi.listOperationLogs(),
        _systemLogsApi.getSystemLogsOverview(),
        _systemLogsApi.listRecentLoginLogs(limit: recentLimit),
        _systemLogsApi.listRecentOperationLogs(limit: recentLimit),
      ]);

      loginLogs.assignAll(results[0] as List<LoginLog>);
      operationLogs.assignAll(results[1] as List<OperationLog>);
      systemOverview.assignAll(results[2] as Map<String, dynamic>);
      recentLoginLogs.assignAll(results[3] as List<LoginLog>);
      recentOperationLogs.assignAll(results[4] as List<OperationLog>);
    });
  }

  Future<void> clear() async {
    loginLogs.clear();
    operationLogs.clear();
    systemOverview.clear();
    recentLoginLogs.clear();
    recentOperationLogs.clear();
    errorMessage.value = '';
  }

  Future<void> _load(Future<void> Function() action) async {
    await runWithLoading(
      () async {
        await _ensureAuthenticated();
        await action();
      },
      errorMessageBuilder: (error) => error is ApiException && error.code == 403
          ? 'Unauthorized'
          : error.toString(),
      onError: _handleError,
    );
  }

  Future<void> _ensureAuthenticated() async {
    if (!Get.isRegistered<AuthService>()) return;
    final isValid = await Get.find<AuthService>().ensureValidSession(
      redirectIfInvalid: true,
    );
    if (!isValid) {
      throw StateError('Session is invalid or expired');
    }
  }

  Future<void> _handleError(Object error, StackTrace stackTrace) async {
    developer.log(
      'Failed to load log data',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is ApiException && error.code == 403) {
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().handleForbidden(source: 'LogController');
      }
      errorMessage.value = 'Unauthorized';
      return;
    }

    errorMessage.value = error.toString();
  }
}
