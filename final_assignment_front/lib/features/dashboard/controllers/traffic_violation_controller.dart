import 'package:final_assignment_front/core/errors/app_exception.dart';
import 'package:final_assignment_front/core/errors/exception_mapper.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/offense/repositories/traffic_violation_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class TrafficViolationController extends GetxController {
  TrafficViolationController(this._repository);

  final TrafficViolationRepository _repository;

  final RxList<OffenseInformation> violations = <OffenseInformation>[].obs;
  final RxMap<String, int> violationTypes = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> timeSeries = <Map<String, dynamic>>[].obs;
  final RxMap<String, int> appealReasons = <String, int>{}.obs;
  final RxMap<String, int> paymentStatus = <String, int>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime> startTime =
      DateTime.now().subtract(const Duration(days: 30)).obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await _repository.getViolations();
      violations.assignAll(data);
      _rebuildDashboardMetrics(data);
    } catch (error) {
      final appException =
          error is AppException ? error : ExceptionMapper.map(error);
      errorMessage.value = appException.message;
      if (kDebugMode) {
        debugPrint('TrafficViolation dashboard load failed: $appException');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<OffenseInformation>> loadByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    return _repository.getViolationsByStatus(
      processStatus: processStatus,
      page: page,
      size: size,
    );
  }

  Future<Map<String, dynamic>> loadDetails(int offenseId) {
    return _repository.getViolationDetails(offenseId: offenseId);
  }

  void _rebuildDashboardMetrics(List<OffenseInformation> data) {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 30));
    startTime.value = windowStart;

    violationTypes.assignAll(
      _countBy(
        data,
        (item) => item.offenseType ?? item.offenseDescription,
        fallback: 'Unknown Type',
      ),
    );
    timeSeries.assignAll(_buildTimeSeries(data, windowStart));
    paymentStatus.assignAll(_buildPaymentStatus(data));
    appealReasons.assignAll(
      _countBy(
        data,
        (item) => item.processResult ?? item.remarks,
      ),
    );
  }

  Map<String, int> _countBy(
    Iterable<OffenseInformation> data,
    String? Function(OffenseInformation item) selector, {
    String? fallback,
  }) {
    final result = <String, int>{};
    for (final item in data) {
      final raw = selector(item)?.trim();
      final key = raw == null || raw.isEmpty ? fallback : raw;
      if (key == null || key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  List<Map<String, dynamic>> _buildTimeSeries(
    List<OffenseInformation> data,
    DateTime windowStart,
  ) {
    final daily = <DateTime, _DailyTrafficMetric>{};

    for (final item in data) {
      final offenseTime = item.offenseTime;
      if (offenseTime == null || offenseTime.isBefore(windowStart)) {
        continue;
      }

      final day = DateTime(
        offenseTime.year,
        offenseTime.month,
        offenseTime.day,
      );
      final metric = daily.putIfAbsent(day, () => _DailyTrafficMetric());
      metric.fineAmount += item.fineAmount ?? 0;
      metric.deductedPoints += item.deductedPoints ?? 0;
    }

    final entries = daily.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return entries
        .map(
          (entry) => {
            'time': entry.key.toIso8601String(),
            'value1': entry.value.fineAmount,
            'value2': entry.value.deductedPoints,
          },
        )
        .toList();
  }

  Map<String, int> _buildPaymentStatus(List<OffenseInformation> data) {
    var completed = 0;
    var pending = 0;

    for (final item in data) {
      final status = (item.processStatus ?? '').toLowerCase();
      if (status.contains('paid') ||
          status.contains('complete') ||
          status.contains('closed') ||
          status.contains('processed')) {
        completed++;
      } else {
        pending++;
      }
    }

    return {
      if (completed > 0) 'Completed/Paid': completed,
      if (pending > 0) 'Pending/Unpaid': pending,
    };
  }
}

class _DailyTrafficMetric {
  double fineAmount = 0;
  int deductedPoints = 0;
}
