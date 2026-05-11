import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum OffenseFormMode { create, edit }

class OffenseFormController extends GetxController {
  OffenseFormController({
    required this.mode,
    this.initialOffense,
  });

  final OffenseFormMode mode;
  final OffenseInformation? initialOffense;
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();

  final formKey = GlobalKey<FormState>();
  final driverNameController = TextEditingController();
  final licensePlateController = TextEditingController();
  final offenseTypeController = TextEditingController();
  final offenseCodeController = TextEditingController();
  final offenseLocationController = TextEditingController();
  final offenseTimeController = TextEditingController();
  final deductedPointsController = TextEditingController();
  final fineAmountController = TextEditingController();
  final processStatusController = TextEditingController();
  final processResultController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool get isEdit => mode == OffenseFormMode.edit;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<bool> validateJwtToken() async {
    final jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      errorMessage.value = '未授权，请重新登录';
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        errorMessage.value = '登录已过期，请重新登录';
        return false;
      }
      return true;
    } catch (e) {
      errorMessage.value = '无效的登录信息，请重新登录';
      return false;
    }
  }

  Future<void> initialize() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await validateJwtToken()) return;
      await offenseApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt();
      if (isEdit) {
        _initializeFields(initialOffense);
      } else {
        processStatusController.text = _getOffenseProcessStatusLabel(
            OffenseProcessStatus.unprocessed.code);
      }
    } catch (e) {
      errorMessage.value = '初始化失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _initializeFields(OffenseInformation? offense) {
    if (offense == null) return;
    driverNameController.text = offense.driverName ?? '';
    licensePlateController.text = offense.licensePlate ?? '';
    offenseTypeController.text = offense.offenseType ?? '';
    offenseCodeController.text = offense.offenseCode ?? '';
    offenseLocationController.text = offense.offenseLocation ?? '';
    offenseTimeController.text = _formatDate(offense.offenseTime);
    deductedPointsController.text = offense.deductedPoints?.toString() ?? '';
    fineAmountController.text = offense.fineAmount?.toString() ?? '';
    processStatusController.text =
        _getOffenseProcessStatusLabel(offense.processStatus);
    processResultController.text = offense.processResult ?? '';
  }

  Future<List<String>> fetchDriverNameSuggestions(String prefix) async {
    try {
      if (!await validateJwtToken()) return [];
      final vehicles = await vehicleApi.apiVehiclesSearchGeneralGet(
        keywords: prefix,
        page: 1,
        size: 10,
      );
      return vehicles
          .map((v) => v.ownerName ?? '')
          .where((name) => name.toLowerCase().contains(prefix.toLowerCase()))
          .toSet()
          .toList();
    } catch (e) {
      errorMessage.value = '获取驾驶员姓名建议失败: $e';
      return [];
    }
  }

  Future<List<String>> fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await validateJwtToken()) return [];
      return await vehicleApi.apiVehiclesSearchLicenseGlobalGet(prefix: prefix);
    } catch (e) {
      errorMessage.value = '获取车牌号建议失败: $e';
      return [];
    }
  }

  void setOffenseDate(DateTime date) {
    offenseTimeController.text = _formatDate(date);
  }

  Future<bool> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    if (!await validateJwtToken()) return false;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final idempotencyKey = _generateIdempotencyKey();
      final payload = _buildPayload(idempotencyKey: idempotencyKey);
      if (isEdit) {
        final offenseId = initialOffense?.offenseId;
        if (offenseId == null) {
          throw Exception('缺少违法记录ID');
        }
        await offenseApi.apiOffensesOffenseIdPut(
          offenseId: offenseId,
          offenseInformation: payload,
          idempotencyKey: idempotencyKey,
        );
      } else {
        await offenseApi.apiOffensesPost(
          offenseInformation: payload,
          idempotencyKey: idempotencyKey,
        );
      }
      return true;
    } catch (e) {
      errorMessage.value = isEdit ? '更新违法行为记录失败: $e' : '创建违法行为记录失败: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  OffenseInformation _buildPayload({required String idempotencyKey}) {
    final offenseTime =
        DateTime.parse('${offenseTimeController.text.trim()}T00:00:00.000');
    return OffenseInformation(
      offenseId: initialOffense?.offenseId,
      offenseTime: offenseTime,
      driverName: driverNameController.text.trim(),
      licensePlate: licensePlateController.text.trim(),
      offenseType: offenseTypeController.text.trim(),
      offenseCode: offenseCodeController.text.trim(),
      offenseLocation: offenseLocationController.text.trim(),
      deductedPoints: deductedPointsController.text.trim().isEmpty
          ? null
          : int.parse(deductedPointsController.text.trim()),
      fineAmount: fineAmountController.text.trim().isEmpty
          ? null
          : double.parse(fineAmountController.text.trim()),
      processStatus: initialOffense?.processStatus ??
          OffenseProcessStatus.unprocessed.code,
      processResult: processResultController.text.trim().isEmpty
          ? null
          : processResultController.text.trim(),
      idempotencyKey: isEdit ? null : idempotencyKey,
    );
  }

  String _generateIdempotencyKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未设置';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getOffenseProcessStatusLabel(String? status) {
    return OffenseProcessStatus.fromCode(status)?.label ?? status ?? '未知';
  }

  @override
  void onClose() {
    driverNameController.dispose();
    licensePlateController.dispose();
    offenseTypeController.dispose();
    offenseCodeController.dispose();
    offenseLocationController.dispose();
    offenseTimeController.dispose();
    deductedPointsController.dispose();
    fineAmountController.dispose();
    processStatusController.dispose();
    processResultController.dispose();
    super.onClose();
  }
}
