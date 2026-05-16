import 'dart:convert';

import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/shared/controllers/base_list_controller.dart';
import 'package:final_assignment_front/shared/utils/error_handler.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressController extends BaseListController<ProgressItem> {
  final ApiClient apiClient = ApiClient();
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  RxList<ProgressItem> get progressItems => items;
  final RxList<ProgressItem> filteredItems = <ProgressItem>[].obs;
  final RxList<AppealRecordModel> appeals = <AppealRecordModel>[].obs;
  final RxList<String> statusCategories =
      ['Pending', 'Processing', 'Completed', 'Archived'].obs;
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
    await fetchAppeals();
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
      final response = await appealApi.apiClient.invokeAPI(
        '/api/appeals',
        'GET',
        const [],
        null,
        {},
        const {},
        null,
        ['bearerAuth'],
        passThroughStatusCodes: const {404},
      );
      if (response.statusCode == 404 || response.body.isEmpty) {
        appeals.clear();
        return;
      }
      final List<dynamic> data = jsonDecode(response.body);
      appeals.value = data
          .map((json) =>
              AppealRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      errorMessage.value = ErrorHandler.extractMessage(e, fallback: '进度数据加载失败');
    }
  }

  Future<void> fetchProgress() async {
    await runWithLoading(() async {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('JWT Token not found');
      }

      final response = await apiClient.invokeAPI(
        '/api/progress',
        'GET',
        [],
        null,
        {'Authorization': 'Bearer $jwtToken'},
        {},
        'application/json',
        ['bearerAuth'],
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        progressItems.value =
            data.map((json) => ProgressItem.fromJson(json)).toList();
        filteredItems.value = progressItems;
      } else {
        throw AppException.http(
            response.statusCode, 'Failed to fetch progress');
      }
    });
  }

  Future<void> submitProgress(String title, String? details,
      {int? appealId}) async {
    await runWithLoading(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final jwtToken = prefs.getString('jwtToken');
        final username = prefs.getString('userName');
        if (jwtToken == null || username == null) {
          throw Exception('JWT Token or username not found');
        }

        final progressItem = ProgressItem(
          title: title,
          details: details,
          status: 'Pending',
          submitTime: DateTime.now(),
          username: username,
          appealId: appealId,
        );

        final response = await apiClient.invokeAPI(
          '/api/progress',
          'POST',
          [],
          progressItem.toJson(),
          {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          {},
          'application/json',
          ['bearerAuth'],
        );

        if (response.statusCode == 201) {
          await fetchProgress();
          _showSnackbar('成功', '进度提交成功');
        } else {
          throw AppException.http(
              response.statusCode, 'Failed to submit progress');
        }
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
        final jwtToken = prefs.getString('jwtToken');
        final username = prefs.getString('username');
        if (jwtToken == null || username == null) {
          throw Exception('JWT Token or username not found');
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

        final response = await apiClient.invokeAPI(
          '/api/progress/$id',
          'PUT',
          [],
          updatedItem.toJson(),
          {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          {},
          'application/json',
          ['bearerAuth'],
        );

        if (response.statusCode == 200) {
          await fetchProgress();
          _showSnackbar('成功', '进度更新成功');
        } else {
          throw AppException.http(
              response.statusCode, 'Failed to update progress');
        }
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  Future<void> updateProgressStatus(int id, String newStatus) async {
    await runWithLoading(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final jwtToken = prefs.getString('jwtToken');
        if (jwtToken == null) {
          throw Exception('JWT Token not found');
        }

        final progressItem = progressItems.firstWhere((item) => item.id == id);
        final updatedItem = progressItem.copyWith(
          status: newStatus,
          submitTime: DateTime.now(),
        );

        final response = await apiClient.invokeAPI(
          '/api/progress/$id',
          'PUT',
          [],
          updatedItem.toJson(),
          {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          {},
          'application/json',
          ['bearerAuth'],
        );

        if (response.statusCode == 200) {
          await fetchProgress();
          _showSnackbar('成功', '状态更新成功');
        } else {
          throw AppException.http(
              response.statusCode, 'Failed to update status');
        }
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  Future<void> deleteProgress(int id) async {
    await runWithLoading(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final jwtToken = prefs.getString('jwtToken');
        if (jwtToken == null) {
          throw Exception('JWT Token not found');
        }

        final response = await apiClient.invokeAPI(
          '/api/progress/$id',
          'DELETE',
          [],
          null,
          {'Authorization': 'Bearer $jwtToken'},
          {},
          'application/json',
          ['bearerAuth'],
        );

        if (response.statusCode == 204) {
          await fetchProgress();
          _showSnackbar('成功', '进度删除成功');
        } else {
          throw AppException.http(
              response.statusCode, 'Failed to delete progress');
        }
      },
      onError: (_, __) =>
          _showSnackbar('错误', errorMessage.value, isError: true),
    );
  }

  void filterByStatus(String status) {
    filteredItems.value =
        progressItems.where((item) => item.status == status).toList();
  }

  Future<void> fetchProgressByTimeRange(DateTime start, DateTime end) async {
    await runWithLoading(() async {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('JWT Token not found');
      }

      final response = await apiClient.invokeAPI(
        '/api/progress?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        'GET',
        [],
        null,
        {'Authorization': 'Bearer $jwtToken'},
        {},
        'application/json',
        ['bearerAuth'],
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        filteredItems.value =
            data.map((json) => ProgressItem.fromJson(json)).toList();
      } else {
        throw AppException.http(
            response.statusCode, 'Failed to fetch progress by time range');
      }
    });
  }

  void clearTimeRangeFilter() {
    filteredItems.value = progressItems;
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
    if (item.offenseId != null) contexts.add('违章ID: ${item.offenseId}');
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
