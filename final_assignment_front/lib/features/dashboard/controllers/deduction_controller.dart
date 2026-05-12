import 'package:final_assignment_front/core/errors/app_exception.dart';
import 'package:final_assignment_front/core/errors/exception_mapper.dart';
import 'package:final_assignment_front/features/model/deduction_record.dart';
import 'package:final_assignment_front/features/offense/repositories/deduction_repository.dart';
import 'package:final_assignment_front/shared/controllers/base_list_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class DeductionController extends BaseListController<DeductionRecordModel> {
  DeductionController(this._repository);

  final DeductionRepository _repository;
  final Uuid _uuid = const Uuid();

  RxList<DeductionRecordModel> get deductions => items;
  final RxList<DeductionRecordModel> filteredDeductions =
      <DeductionRecordModel>[].obs;
  final RxBool isAdmin = false.obs;
  final RxBool hasMore = true.obs;
  final RxString searchType = 'handler'.obs;
  final Rxn<DateTime> startTime = Rxn<DateTime>();
  final Rxn<DateTime> endTime = Rxn<DateTime>();

  int currentPage = 1;
  int pageSize = 20;

  @override
  Future<void> fetchData() => initialize();

  Future<void> initialize() {
    return runWithLoading(() async {
      await _repository.initializeWithJwt();
      isAdmin.value = await _repository.isCurrentUserAdmin();
      if (!isAdmin.value) {
        throw const AppException(
          type: AppErrorType.forbidden,
          message: '权限不足：仅管理员可访问此页面',
          statusCode: 403,
        );
      }
      await loadDeductions(reset: true, manageLoading: false);
    });
  }

  Future<void> loadDeductions({
    bool reset = false,
    String? query,
    bool manageLoading = true,
  }) {
    return runWithLoading(
      () async {
        if (!isAdmin.value || (!hasMore.value && !reset)) return;

        if (reset) {
          currentPage = 1;
          hasMore.value = true;
          deductions.clear();
          filteredDeductions.clear();
        }

        final loaded = await _repository.findDeductions(
          searchType: searchType.value,
          query: query,
          startTime: startTime.value,
          endTime: endTime.value,
          page: currentPage,
          size: pageSize,
        );

        deductions.addAll(loaded);
        hasMore.value = loaded.length == pageSize;
        applyFilters(query ?? '');
        if (reset) currentPage = 1;
        currentPage++;

        if (filteredDeductions.isEmpty) {
          final hasFilter = (query?.trim().isNotEmpty ?? false) ||
              (startTime.value != null && endTime.value != null);
          errorMessage.value = hasFilter ? '未找到符合条件的扣分记录' : '暂无扣分记录';
        }
      },
      manageLoading: manageLoading,
    );
  }

  void applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    filteredDeductions.assignAll(
      deductions.where((deduction) {
        final handler = (deduction.handler ?? '').toLowerCase();
        final deductionTime = deduction.deductionTime;

        var matchesQuery = true;
        if (searchQuery.isNotEmpty && searchType.value == 'handler') {
          matchesQuery = handler.contains(searchQuery);
        }

        var matchesDateRange = true;
        final start = startTime.value;
        final end = endTime.value;
        if (start != null && end != null && deductionTime != null) {
          matchesDateRange = deductionTime.isAfter(start) &&
              deductionTime.isBefore(end.add(const Duration(days: 1)));
        } else if (start != null && end != null && deductionTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }),
    );

    if (filteredDeductions.isEmpty && deductions.isNotEmpty) {
      errorMessage.value = '未找到符合条件的扣分记录';
    } else {
      errorMessage.value =
          filteredDeductions.isEmpty && deductions.isEmpty ? '暂无扣分记录' : '';
    }
  }

  Future<bool> createDeduction(DeductionRecordModel deduction) {
    return _runBool(() async {
      await _repository.createDeduction(
        body: deduction,
        idempotencyKey: _uuid.v4(),
      );
      await loadDeductions(reset: true, manageLoading: false);
    });
  }

  Future<bool> updateDeduction({
    required int deductionId,
    required DeductionRecordModel deduction,
  }) {
    return _runBool(() async {
      await _repository.updateDeduction(
        deductionId: deductionId,
        body: deduction,
        idempotencyKey: _uuid.v4(),
      );
      await loadDeductions(reset: true, manageLoading: false);
    });
  }

  Future<bool> deleteDeduction(int deductionId) {
    return _runBool(() async {
      await _repository.deleteDeduction(deductionId: deductionId);
      deductions.removeWhere((item) => item.deductionId == deductionId);
      filteredDeductions.removeWhere((item) => item.deductionId == deductionId);
    });
  }

  void setSearchType(String value) {
    searchType.value = value;
    startTime.value = null;
    endTime.value = null;
  }

  Future<void> setDateRange(DateTime start, DateTime end) {
    startTime.value = start;
    endTime.value = end;
    searchType.value = 'timeRange';
    return loadDeductions(reset: true);
  }

  Future<void> clearFilters() {
    searchType.value = 'handler';
    startTime.value = null;
    endTime.value = null;
    return loadDeductions(reset: true);
  }

  Future<bool> _runBool(Future<void> Function() action) async {
    var success = false;
    await runWithLoading(() async {
      await action();
      success = true;
    });
    return success;
  }

  @override
  String getErrorMessage(Object error) => _mapError(error).message;

  @override
  void onAsyncError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('DeductionController error: ${_mapError(error)}');
    }
  }

  AppException _mapError(Object error) {
    return error is AppException ? error : ExceptionMapper.map(error);
  }
}
