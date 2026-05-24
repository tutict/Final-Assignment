import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/shared/controllers/base_list_controller.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressController extends BaseListController<ProgressItem> {
  final ProgressControllerApi progressApi = ProgressControllerApi();
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  RxList<ProgressItem> get progressItems => items;
  final RxList<ProgressItem> filteredItems = <ProgressItem>[].obs;
  final RxList<AppealRecordModel> appeals = <AppealRecordModel>[].obs;
  final RxList<String> statusCategories =
      ['Pending', 'Processing', 'Completed', 'Archived'].obs;
  final Rxn<String> selectedStatus = Rxn<String>();
  final Rxn<DateTime> selectedStartDate = Rxn<DateTime>();
  final Rxn<DateTime> selectedEndDate = Rxn<DateTime>();
  final RxBool _isAdmin = false.obs;

  void _showSnackbar(String title, String message, {bool isError = false}) {
    final ctx = Get.context;
    if (ctx != null) {
      if (isError) {
        AppSnackbar.showError(ctx, message: message);
      } else {
        AppSnackbar.showSuccess(ctx, message: message);
      }
    } else {
      Get.snackbar(title, message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: isError ? Get.theme.colorScheme.error : null,
          colorText: isError ? Get.theme.colorScheme.onError : null);
    }
  }

  @override
  Future<void> fetchData() async {
    await _loadUserRole();
    await fetchProgress();
    if (isAdmin) {
      await fetchAppeals();
    }
  }

  bool get isAdmin => _isAdmin.value;

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    if (token == null || token.isEmpty) {
      _isAdmin.value = false;
      return;
    }
    try {
      final decoded = JwtDecoder.decode(token);
      final roles = decoded['roles'];
      if (roles is List) {
        _isAdmin.value = roles
            .map((e) => e.toString())
            .any((role) => role.contains('ADMIN'));
      } else if (roles is String) {
        _isAdmin.value = roles.contains('ADMIN');
      } else {
        _isAdmin.value = false;
      }
    } catch (_) {
      _isAdmin.value = false;
    }
  }

  Future<void> fetchAppeals() async {
    try {
      await appealApi.initializeWithJwt();
      appeals.value = await appealApi.listAllAppeals();
    } catch (_) {
      appeals.clear();
    }
  }

  Future<void> fetchProgress() async {
    await runWithLoading(() async {
      await progressApi.initializeWithJwt();
      progressItems.value = await progressApi.listProgressItems();
      _applyActiveFilters();
    });
  }

  Future<void> submitProgress(String title, String? details,
      {int? appealId}) async {
    await runWithLoading(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('userName');
        if (username == null) {
          throw Exception('username not found');
        }

        final progressItem = ProgressItem(
          title: title,
          details: details,
          status: 'Pending',
          submitTime: DateTime.now(),
          username: username,
          appealId: appealId,
        );

        await progressApi.createProgressItem(progressItem: progressItem);
        await fetchProgress();
        _showSnackbar('成功', '进度提交成功');
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  Future<void> updateProgress(
      int id, String title, String? details, String status,
      {int? appealId}) async {
    await runWithLoading(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username');
        if (username == null) {
          throw Exception('username not found');
        }

        final progressItem = progressItems.firstWhere((item) => item.id == id);
        final updatedItem = progressItem.copyWith(
          title: title,
          details: details,
          status: status,
          submitTime: DateTime.now(),
          username: username,
          appealId: appealId ?? progressItem.appealId,
        );

        await progressApi.updateProgressItem(
          progressId: id,
          progressItem: updatedItem,
        );
        await fetchProgress();
        _showSnackbar('成功', '进度更新成功');
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  Future<void> updateProgressStatus(int id, String newStatus) async {
    await runWithLoading(
      () async {
        final progressItem = progressItems.firstWhere((item) => item.id == id);
        final updatedItem = progressItem.copyWith(
          status: newStatus,
          submitTime: DateTime.now(),
        );

        await progressApi.updateProgressItem(
          progressId: id,
          progressItem: updatedItem,
        );
        await fetchProgress();
        _showSnackbar('成功', '状态更新成功');
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  Future<void> deleteProgress(int id) async {
    await runWithLoading(
      () async {
        await progressApi.deleteProgressItem(progressId: id);
        await fetchProgress();
        _showSnackbar('成功', '进度删除成功');
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    _applyActiveFilters();
  }

  Future<void> fetchProgressByTimeRange(DateTime start, DateTime end) async {
    await runWithLoading(() async {
      selectedStatus.value = null;
      selectedStartDate.value = start;
      selectedEndDate.value = end;
      filteredItems.value = await progressApi.searchProgressItemsByTimeRange(
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
      );
    });
  }

  void clearTimeRangeFilter() {
    clearFilters();
  }

  void clearFilters() {
    selectedStatus.value = null;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    filteredItems.value = progressItems.toList();
  }

  void _applyActiveFilters() {
    Iterable<ProgressItem> nextItems = progressItems;
    final status = selectedStatus.value;
    final start = selectedStartDate.value;
    final end = selectedEndDate.value;

    if (status != null && status.isNotEmpty) {
      nextItems = nextItems.where((item) => item.status == status);
    }

    if (start != null && end != null) {
      final inclusiveEnd = end.add(const Duration(days: 1));
      nextItems = nextItems.where(
        (item) =>
            !item.submitTime.isBefore(start) &&
            item.submitTime.isBefore(inclusiveEnd),
      );
    }

    filteredItems.value = nextItems.toList();
  }

  @override
  String getErrorMessage(Object error) => _formatErrorMessage(error);

  String getBusinessContext(ProgressItem item) {
    final contexts = <String>[];
    if (item.appealId != null) contexts.add('申诉ID: ${item.appealId}');
    if (item.deductionId != null) contexts.add('扣分ID: ${item.deductionId}');
    if (item.driverId != null) contexts.add('司机ID: ${item.driverId}');
    if (item.fineId != null) contexts.add('罚款ID: ${item.fineId}');
    if (item.vehicleId != null) contexts.add('车辆ID: ${item.vehicleId}');
    if (item.offenseId != null) contexts.add('违法ID: ${item.offenseId}');
    return contexts.isNotEmpty ? contexts.join(', ') : '无关联业务';
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }
}
