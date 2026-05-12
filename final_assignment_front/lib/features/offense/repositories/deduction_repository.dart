import 'package:final_assignment_front/core/errors/app_exception.dart';
import 'package:final_assignment_front/core/repository/base_repository.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/model/deduction_record.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

abstract class DeductionRepository {
  Future<void> initializeWithJwt();

  Future<bool> isCurrentUserAdmin();

  Future<List<DeductionRecordModel>> getDeductions();

  Future<DeductionRecordModel?> getDeduction({
    required int deductionId,
  });

  Future<DeductionRecordModel> createDeduction({
    required DeductionRecordModel body,
    required String idempotencyKey,
    bool clearCacheAfterWrite = true,
  });

  Future<DeductionRecordModel> updateDeduction({
    required int deductionId,
    required DeductionRecordModel body,
    required String idempotencyKey,
    bool clearCacheAfterWrite = true,
  });

  Future<void> deleteDeduction({
    required int deductionId,
    bool clearCacheAfterWrite = true,
  });

  Future<List<DeductionRecordModel>> getDeductionsByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  });

  Future<List<DeductionRecordModel>> getDeductionsByOffense({
    required int offenseId,
    int page = 1,
    int size = 20,
  });

  Future<List<DeductionRecordModel>> searchByHandler({
    required String handler,
    String mode = 'prefix',
    int page = 1,
    int size = 20,
  });

  Future<List<DeductionRecordModel>> searchByStatus({
    required String status,
    int page = 1,
    int size = 20,
  });

  Future<List<DeductionRecordModel>> searchByTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    int page = 1,
    int size = 20,
  });

  Future<List<DeductionRecordModel>> findDeductions({
    String searchType = 'handler',
    String? query,
    DateTime? startTime,
    DateTime? endTime,
    int page = 1,
    int size = 20,
  });

  Future<void> clearCache();
}

class DeductionRepositoryImpl extends BaseRepository
    implements DeductionRepository {
  DeductionRepositoryImpl(
    DeductionInformationControllerApi api, {
    ApiClient? apiClient,
  })  : _api = api,
        _apiClient = apiClient ?? api.apiClient;

  final DeductionInformationControllerApi _api;
  final ApiClient _apiClient;

  @override
  Future<void> initializeWithJwt() {
    return guard(() => _api.initializeWithJwt());
  }

  @override
  Future<bool> isCurrentUserAdmin() {
    return guard(() async {
      final token = await AuthTokenStore.instance.getJwtToken();
      if (token == null || token.isEmpty) {
        throw const AppException(
          type: AppErrorType.unauthorized,
          message: '未授权，请重新登录',
          statusCode: 401,
        );
      }
      if (JwtDecoder.isExpired(token)) {
        throw const AppException(
          type: AppErrorType.unauthorized,
          message: '登录已过期，请重新登录',
          statusCode: 401,
        );
      }

      final decoded = JwtDecoder.decode(token);
      final roles = decoded['roles'];
      if (roles is String) return roles.contains('ADMIN');
      if (roles is Iterable) {
        return roles.map((role) => role.toString()).contains('ADMIN');
      }
      return false;
    });
  }

  @override
  Future<List<DeductionRecordModel>> getDeductions() {
    return guard(() async {
      await _api.initializeWithJwt();
      final deductions = await _api.listDeductions();
      return _sortByDeductionTimeDesc(deductions);
    });
  }

  @override
  Future<DeductionRecordModel?> getDeduction({
    required int deductionId,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.getDeduction(deductionId: deductionId);
    });
  }

  @override
  Future<DeductionRecordModel> createDeduction({
    required DeductionRecordModel body,
    required String idempotencyKey,
    bool clearCacheAfterWrite = true,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      final created = await _api.createDeduction(
        body: body,
        idempotencyKey: idempotencyKey,
      );
      if (clearCacheAfterWrite) {
        await _clearCacheUnsafe();
      }
      return created;
    });
  }

  @override
  Future<DeductionRecordModel> updateDeduction({
    required int deductionId,
    required DeductionRecordModel body,
    required String idempotencyKey,
    bool clearCacheAfterWrite = true,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      final updated = await _api.updateDeduction(
        deductionId: deductionId,
        body: body,
        idempotencyKey: idempotencyKey,
      );
      if (clearCacheAfterWrite) {
        await _clearCacheUnsafe();
      }
      return updated;
    });
  }

  @override
  Future<void> deleteDeduction({
    required int deductionId,
    bool clearCacheAfterWrite = true,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      await _api.deleteDeduction(deductionId: deductionId);
      if (clearCacheAfterWrite) {
        await _clearCacheUnsafe();
      }
    });
  }

  @override
  Future<List<DeductionRecordModel>> getDeductionsByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.listDeductionsByDriver(
        driverId: driverId,
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<DeductionRecordModel>> getDeductionsByOffense({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.listDeductionsByOffense(
        offenseId: offenseId,
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<DeductionRecordModel>> searchByHandler({
    required String handler,
    String mode = 'prefix',
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchDeductionsByHandler(
        handler: handler,
        mode: mode,
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<DeductionRecordModel>> searchByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchDeductionsByStatus(
        status: status,
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<DeductionRecordModel>> searchByTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchDeductionsByTimeRange(
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<DeductionRecordModel>> findDeductions({
    String searchType = 'handler',
    String? query,
    DateTime? startTime,
    DateTime? endTime,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      final trimmedQuery = query?.trim() ?? '';

      if (searchType == 'handler' && trimmedQuery.isNotEmpty) {
        return searchByHandler(
          handler: trimmedQuery,
          page: page,
          size: size,
        );
      }

      if (searchType == 'status' && trimmedQuery.isNotEmpty) {
        return searchByStatus(
          status: trimmedQuery,
          page: page,
          size: size,
        );
      }

      if (searchType == 'timeRange' && startTime != null && endTime != null) {
        return searchByTimeRange(
          startTime: startTime,
          endTime: endTime.add(const Duration(days: 1)),
          page: page,
          size: size,
        );
      }

      if (page > 1) {
        return <DeductionRecordModel>[];
      }
      return getDeductions();
    });
  }

  @override
  Future<void> clearCache() {
    return guard(_clearCacheUnsafe);
  }

  Future<void> _clearCacheUnsafe() async {
    await _apiClient.invokeAPI(
      '/api/cache/clear',
      'POST',
      const [],
      null,
      <String, String>{},
      <String, String>{},
      null,
      const ['bearerAuth'],
    );
  }

  List<DeductionRecordModel> _sortByDeductionTimeDesc(
    List<DeductionRecordModel> deductions,
  ) {
    return [...deductions]..sort((left, right) {
        final leftTime = left.deductionTime ?? DateTime(1970);
        final rightTime = right.deductionTime ?? DateTime(1970);
        return rightTime.compareTo(leftTime);
      });
  }
}
