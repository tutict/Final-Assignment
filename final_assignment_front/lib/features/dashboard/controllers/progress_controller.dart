import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressController extends GetxController {
  final ProgressControllerApi _progressApi = ProgressControllerApi();
  final AppealManagementControllerApi _appealApi =
  AppealManagementControllerApi();
  final DeductionInformationControllerApi _deductionApi =
  DeductionInformationControllerApi();
  final DriverInformationControllerApi _driverApi =
  DriverInformationControllerApi();
  final FineInformationControllerApi _fineApi = FineInformationControllerApi();
  final VehicleInformationControllerApi _vehicleApi =
  VehicleInformationControllerApi();
  final OffenseInformationControllerApi _offenseApi =
  OffenseInformationControllerApi();

  var progressItems = <ProgressItem>[].obs;
  var filteredItems = <ProgressItem>[].obs;
  var appeals = <AppealManagement>[].obs;
  var deductions = <DeductionInformation>[].obs;
  var drivers = <DriverInformation>[].obs;
  var fines = <FineInformation>[].obs;
  var vehicles = <VehicleInformation>[].obs;
  var offenses = <OffenseInformation>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var currentUsername = ''.obs;
  var isAdmin = false.obs;

  final List<String> statusCategories = [
    'Pending',
    'Processing',
    'Completed',
    'Archived'
  ];

  // 用于时间范围筛选
  var startTime = Rxn<DateTime>();
  var endTime = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      currentUsername.value = prefs.getString('userName') ?? '';

      if (jwtToken == null || currentUsername.value.isEmpty) {
        throw Exception('未登录或未找到用户信息');
      }

      await _progressApi.initializeWithJwt();
      await _appealApi.initializeWithJwt();
      await _deductionApi.initializeWithJwt();
      await _driverApi.initializeWithJwt();
      await _fineApi.initializeWithJwt();
      await _vehicleApi.initializeWithJwt();
      await _offenseApi.initializeWithJwt();
      await checkUserRole(jwtToken);
      await fetchBusinessData();
      await fetchProgress();
    } catch (e) {
      errorMessage.value = '初始化失败: $e';
      Get.snackbar('错误', '初始化失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkUserRole(String jwtToken) async {
    try {
      final decoded = _decodeJwt(jwtToken);
      final roles = decoded['roles'] is String
          ? [decoded['roles'].toString()]
          : (decoded['roles'] as List<dynamic>?)
          ?.map((r) => r.toString())
          .toList() ??
          [];
      debugPrint('Roles from JWT: $roles'); // 调试日志
      isAdmin.value = roles.contains('ROLE_ADMIN') || roles.contains('ADMIN');
      debugPrint('isAdmin set to: ${isAdmin.value}');
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      isAdmin.value = false;
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> fetchBusinessData() async {
    try {
      if (isAdmin.value) {
        appeals.assignAll(await _appealApi.apiAppealsGet() ?? []);
        deductions.assignAll(await _deductionApi.apiDeductionsGet() ?? []);
        drivers.assignAll(await _driverApi.apiDriversGet() ?? []);
        fines.assignAll(await _fineApi.apiFinesGet() ?? []);
        vehicles.assignAll(await _vehicleApi.apiVehiclesGet() ?? []);
        offenses.assignAll(await _offenseApi.apiOffensesGet() ?? []);
      } else {
        appeals.assignAll(await _appealApi.apiAppealsGet() ?? []);
        deductions.assignAll((await _deductionApi.apiDeductionsGet() ?? [])
            .where((d) => d.handler == currentUsername.value)
            .toList());
        drivers.assignAll((await _driverApi.apiDriversGet() ?? [])
            .where((d) => d.name == currentUsername.value)
            .toList());
        fines.assignAll((await _fineApi.apiFinesGet() ?? [])
            .where((f) => f.payee == currentUsername.value)
            .toList());
        vehicles.assignAll(await _vehicleApi.apiVehiclesSearchGet(
            query: currentUsername.value) ??
            []);
        offenses.assignAll((await _offenseApi.apiOffensesGet() ?? [])
            .where((o) => o.driverName == currentUsername.value)
            .toList());
      }
    } catch (e) {
      errorMessage.value = '加载业务数据失败: $e';
      Get.snackbar('错误', '加载业务数据失败: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> fetchProgress() async {
    isLoading.value = true;
    try {
      if (isAdmin.value) {
        progressItems.assignAll(await _progressApi.apiProgressGet() ?? []);
      } else {
        progressItems.assignAll(await _progressApi.apiProgressUsernameGet(
            username: currentUsername.value) ??
            []);
      }
      applyFilters();
    } catch (e) {
      errorMessage.value = '加载进度失败: $e';
      progressItems.clear();
      Get.snackbar('错误', '加载进度失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatus(String status) {
    applyFilters(status: status);
  }

  Future<void> fetchProgressByTimeRange(DateTime start, DateTime end) async {
    isLoading.value = true;
    try {
      startTime.value = start;
      endTime.value = end;
      final progressList = await _progressApi.apiProgressTimeRangeGet(
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
      );
      progressItems.assignAll(progressList ?? []);
      applyFilters();
    } catch (e) {
      errorMessage.value = '按时间范围加载进度失败: $e';
      progressItems.clear();
      Get.snackbar('错误', '按时间范围加载进度失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters({String? status}) {
    var items = progressItems.toList();

    // 按时间范围过滤
    if (startTime.value != null && endTime.value != null) {
      items = items.where((item) {
        final submitTime = item.submitTime;
        return submitTime.isAfter(startTime.value!) &&
            submitTime.isBefore(endTime.value!);
      }).toList();
    }

    // 按状态过滤
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }

    filteredItems.assignAll(items);
  }

  Future<void> submitProgress(String title, String? details,
      {int? appealId,
        int? deductionId,
        int? driverId,
        int? fineId,
        int? vehicleId,
        int? offenseId}) async {
    if (title.isEmpty) {
      errorMessage.value = '进度标题不能为空';
      Get.snackbar('错误', '进度标题不能为空', backgroundColor: Colors.red);
      return;
    }
    isLoading.value = true;
    try {
      final newItem = ProgressItem(
        id: 0,
        title: title,
        status: 'Pending',
        submitTime: DateTime.now(),
        details: details?.isNotEmpty == true ? details : null,
        username: currentUsername.value,
        appealId: appealId,
        deductionId: deductionId,
        driverId: driverId,
        fineId: fineId,
        vehicleId: vehicleId,
        offenseId: offenseId,
      );
      await _progressApi.apiProgressPost(progressItem: newItem);
      await fetchProgress();
      Get.snackbar('成功', '进度提交成功', backgroundColor: Colors.green);
    } catch (e) {
      errorMessage.value = '提交进度失败: $e';
      Get.snackbar('错误', '提交进度失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProgressStatus(int progressId, String newStatus) async {
    if (!isAdmin.value) {
      Get.snackbar('错误', '只有管理员可以更新进度状态', backgroundColor: Colors.red);
      return;
    }
    isLoading.value = true;
    try {
      await _progressApi.apiProgressProgressIdStatusPut(
        progressId: progressId,
        newStatus: newStatus,
      );
      await fetchProgress();
      Get.snackbar('成功', '状态更新成功', backgroundColor: Colors.green);
    } catch (e) {
      errorMessage.value = '更新状态失败: $e';
      Get.snackbar('错误', '更新状态失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProgress(int progressId) async {
    if (!isAdmin.value) {
      Get.snackbar('错误', '只有管理员可以删除进度', backgroundColor: Colors.red);
      return;
    }
    isLoading.value = true;
    try {
      await _progressApi.apiProgressProgressIdDelete(progressId: progressId);
      await fetchProgress();
      Get.snackbar('成功', '进度删除成功', backgroundColor: Colors.green);
    } catch (e) {
      errorMessage.value = '删除失败: $e';
      Get.snackbar('错误', '删除失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  String getBusinessContext(ProgressItem item) {
    if (item.appealId != null) {
      final appeal =
      appeals.firstWhereOrNull((a) => a.appealId == item.appealId);
      return '申诉: ${appeal?.appellantName ?? "未知"} (ID: ${item.appealId})';
    } else if (item.deductionId != null) {
      final deduction =
      deductions.firstWhereOrNull((d) => d.deductionId == item.deductionId);
      return '扣分: ${deduction?.driverLicenseNumber ?? "未知"} (分数: ${deduction?.deductedPoints ?? 0})';
    } else if (item.driverId != null) {
      final driver =
      drivers.firstWhereOrNull((d) => d.driverId == item.driverId);
      return '司机: ${driver?.name ?? "未知"} (驾照: ${driver?.driverLicenseNumber ?? "未知"})';
    } else if (item.fineId != null) {
      final fine = fines.firstWhereOrNull((f) => f.fineId == item.fineId);
      return '罚款: ${fine?.payee ?? "未知"} (金额: ${fine?.fineAmount ?? 0})';
    } else if (item.vehicleId != null) {
      final vehicle =
      vehicles.firstWhereOrNull((v) => v.vehicleId == item.vehicleId);
      return '车辆: ${vehicle?.licensePlate ?? "未知"} (车主: ${vehicle?.ownerName ?? "未知"})';
    } else if (item.offenseId != null) {
      final offense =
      offenses.firstWhereOrNull((o) => o.offenseId == item.offenseId);
      return '违法: ${offense?.offenseType ?? "未知"} (车牌: ${offense?.licensePlate ?? "未知"})';
    }
    return '无关联业务';
  }

  void clearTimeRangeFilter() {
    startTime.value = null;
    endTime.value = null;
    applyFilters();
  }
}