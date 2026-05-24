import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:get/get.dart';

final ApiClient defaultUserRealtimeApiClient = ApiClient();

class UserRealtimeService extends GetxService {
  UserRealtimeService({ApiClient? apiClient})
      : _api = UserManagementControllerApi(
          apiClient ?? defaultUserRealtimeApiClient,
        );

  final UserManagementControllerApi _api;

  Future<UserManagement?> getCurrentUser({required String username}) async {
    try {
      final user = await _api.getCurrentUser(username: username);
      AppLogger.debug('WebSocket users me get response: ${user.toJson()}');
      return user;
    } on AppException catch (e) {
      if (e.statusCode == 404) {
        AppLogger.debug('WebSocket users me get response: null');
        return null;
      }
      AppLogger.error('WebSocket users me get error: $e');
      rethrow;
    } catch (e) {
      AppLogger.error('WebSocket users me get error: $e');
      rethrow;
    }
  }
}
