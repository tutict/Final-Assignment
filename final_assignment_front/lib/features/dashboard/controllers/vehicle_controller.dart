import 'package:final_assignment_front/core/errors/app_exception.dart';
import 'package:final_assignment_front/core/errors/exception_mapper.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/vehicle/repositories/vehicle_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class VehicleController extends GetxController {
  VehicleController(this._repository);

  final VehicleRepository _repository;
  final Uuid _uuid = const Uuid();

  final RxList<VehicleInformation> vehicles = <VehicleInformation>[].obs;
  final RxList<VehicleInformation> filteredVehicles =
      <VehicleInformation>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchType = 'licensePlate'.obs;
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadVehicles(reset: true);
  }

  Future<void> loadVehicles({bool reset = false, String? query}) {
    return _run(() async {
      if (reset) {
        vehicles.clear();
        filteredVehicles.clear();
        hasMore.value = true;
      }
      if (!hasMore.value) return;

      final loaded = await _repository.getVehicles();
      vehicles.assignAll(loaded);
      hasMore.value = false;
      applyFilters(query ?? '');
    });
  }

  void applyFilters(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    filteredVehicles.assignAll(
      vehicles.where((vehicle) {
        final licensePlate = (vehicle.licensePlate ?? '').toLowerCase();
        final vehicleType = (vehicle.vehicleType ?? '').toLowerCase();
        final registrationDate = vehicle.firstRegistrationDate;

        var matchesQuery = true;
        if (normalizedQuery.isNotEmpty) {
          if (searchType.value == 'licensePlate') {
            matchesQuery = licensePlate.contains(normalizedQuery);
          } else if (searchType.value == 'vehicleType') {
            matchesQuery = vehicleType.contains(normalizedQuery);
          }
        }

        var matchesDateRange = true;
        final start = startDate.value;
        final end = endDate.value;
        if (start != null && end != null && registrationDate != null) {
          matchesDateRange = registrationDate.isAfter(start) &&
              registrationDate.isBefore(end.add(const Duration(days: 1)));
        } else if (start != null && end != null && registrationDate == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }),
    );

    if (filteredVehicles.isEmpty && vehicles.isNotEmpty) {
      errorMessage.value = '未找到符合条件的车辆';
    } else {
      errorMessage.value =
          filteredVehicles.isEmpty && vehicles.isEmpty ? '当前没有车辆记录' : '';
    }
  }

  Future<List<String>> autocompleteSuggestions(String prefix) async {
    final normalizedPrefix = prefix.trim();
    if (normalizedPrefix.isEmpty) return [];

    try {
      final suggestions = searchType.value == 'vehicleType'
          ? await _repository.autocompleteTypesGlobal(prefix: normalizedPrefix)
          : await _repository.autocompleteLicensePlatesGlobal(
              prefix: normalizedPrefix,
            );
      return suggestions
          .where((item) =>
              item.toLowerCase().contains(normalizedPrefix.toLowerCase()))
          .toList();
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  Future<bool> createVehicle(VehicleInformation vehicle) {
    return _runBool(() async {
      final created = await _repository.createVehicle(
        vehicle: vehicle,
        idempotencyKey: _uuid.v4(),
      );
      vehicles.add(created);
      applyFilters('');
    });
  }

  Future<bool> updateVehicle({
    required int vehicleId,
    required VehicleInformation vehicle,
  }) {
    return _runBool(() async {
      final updated = await _repository.updateVehicle(
        vehicleId: vehicleId,
        vehicle: vehicle,
        idempotencyKey: _uuid.v4(),
      );
      final index = vehicles.indexWhere((item) => item.vehicleId == vehicleId);
      if (index >= 0) {
        vehicles[index] = updated;
      }
      applyFilters('');
    });
  }

  Future<bool> deleteVehicle(int vehicleId) {
    return _runBool(() async {
      await _repository.deleteVehicle(vehicleId: vehicleId);
      vehicles.removeWhere((item) => item.vehicleId == vehicleId);
      filteredVehicles.removeWhere((item) => item.vehicleId == vehicleId);
    });
  }

  Future<bool> existsLicensePlate(String licensePlate) async {
    try {
      return await _repository.existsLicensePlate(licensePlate: licensePlate);
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  void setSearchType(String value) {
    searchType.value = value;
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    applyFilters('');
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await action();
    } catch (error) {
      _handleError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _runBool(Future<void> Function() action) async {
    var success = false;
    await _run(() async {
      await action();
      success = true;
    });
    return success;
  }

  void _handleError(Object error) {
    final appException =
        error is AppException ? error : ExceptionMapper.map(error);
    errorMessage.value = appException.message;
    if (Get.context != null) {
      Get.snackbar('操作失败', appException.message);
    }
    if (kDebugMode) {
      debugPrint('VehicleController error: $appException');
    }
  }
}
