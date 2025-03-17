import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProgressController extends GetxController {
  final ProgressControllerApi _progressApi = ProgressControllerApi();
  final AppealManagementControllerApi _appealApi =
      AppealManagementControllerApi();
  final FineInformationControllerApi _fineApi = FineInformationControllerApi();
  final VehicleInformationControllerApi _vehicleApi =
      VehicleInformationControllerApi();

  var progressItems = <ProgressItem>[].obs;
  var filteredItems = <ProgressItem>[].obs;
  var appeals = <AppealManagement>[].obs;
  var fines = <FineInformation>[].obs;
  var vehicles = <VehicleInformation>[].obs;
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
      await _fineApi.initializeWithJwt();
      await _vehicleApi.initializeWithJwt();
      await checkUserRole(jwtToken);
      await fetchBusinessData();
      await fetchProgress();
    } catch (e) {
      errorMessage.value = '初始化失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkUserRole(String jwtToken) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        isAdmin.value = roles.contains('ROLE_ADMIN');
      }
    } catch (e) {
      isAdmin.value = false;
    }
  }

  Future<void> fetchBusinessData() async {
    try {
      if (isAdmin.value) {
        appeals.assignAll(await _appealApi.apiAppealsGet());
        fines.assignAll(await _fineApi.apiFinesGet());
        vehicles.assignAll(await _vehicleApi.apiVehiclesSearchGet(query: ''));
      } else {
        appeals.assignAll(await _appealApi.apiAppealsGet());
        fines.assignAll((await _fineApi.apiFinesGet())
            .where((f) => f.payee == currentUsername.value));
        vehicles.assignAll(await _vehicleApi.apiVehiclesSearchGet(
            query: currentUsername.value));
      }
    } catch (e) {
      errorMessage.value = '加载业务数据失败: $e';
    }
  }

  Future<void> fetchProgress() async {
    isLoading.value = true;
    try {
      if (isAdmin.value) {
        progressItems.assignAll(await _progressApi.apiProgressGet());
      } else {
        progressItems.assignAll(await _progressApi.apiProgressUsernameGet(
            username: currentUsername.value));
      }
      filterByStatus(statusCategories[0]);
    } catch (e) {
      errorMessage.value = '加载进度失败: $e';
      progressItems.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatus(String status) {
    filteredItems.assignAll(
        progressItems.where((item) => item.status == status).toList());
  }

  Future<void> submitProgress(String title, String? details,
      {int? appealId, int? fineId, int? vehicleId}) async {
    if (title.isEmpty) {
      errorMessage.value = '进度标题不能为空';
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
        fineId: fineId,
        vehicleId: vehicleId,
      );
      await _progressApi.apiProgressPost(progressItem: newItem);
      await fetchProgress();
      Get.snackbar('成功', '进度提交成功');
    } catch (e) {
      errorMessage.value = '提交进度失败: $e';
      Get.snackbar('错误', '提交进度失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProgressStatus(int progressId, String newStatus) async {
    if (!isAdmin.value) return;
    isLoading.value = true;
    try {
      final item = progressItems.firstWhere((p) => p.id == progressId);
      final updatedItem = item.copyWith(status: newStatus);
      await _progressApi.apiProgressProgressIdPut(
          progressId: progressId, progressItem: updatedItem);
      await fetchProgress();
      Get.snackbar('成功', '状态更新成功');
    } catch (e) {
      errorMessage.value = '更新状态失败: $e';
      Get.snackbar('错误', '更新状态失败: $e', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProgress(int progressId) async {
    if (!isAdmin.value) return;
    isLoading.value = true;
    try {
      await _progressApi.apiProgressProgressIdDelete(progressId: progressId);
      await fetchProgress();
      Get.snackbar('成功', '进度删除成功');
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
    } else if (item.fineId != null) {
      final fine = fines.firstWhereOrNull((f) => f.fineId == item.fineId);
      return '罚款: ${fine?.payee ?? "未知"} (金额: ${fine?.fineAmount ?? 0})';
    } else if (item.vehicleId != null) {
      final vehicle =
          vehicles.firstWhereOrNull((v) => v.vehicleId == item.vehicleId);
      return '车辆: ${vehicle?.licensePlate ?? "未知"}';
    }
    return '无关联业务';
  }
}
