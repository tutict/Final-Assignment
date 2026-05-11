import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

final ApiClient defaultUserRealtimeApiClient = ApiClient();

class UserRealtimeService extends GetxService {
  UserRealtimeService({ApiClient? apiClient})
      : apiClient = apiClient ?? defaultUserRealtimeApiClient;

  final ApiClient apiClient;

  Future<UserManagement?> getCurrentUser({required String username}) async {
    final msg = {
      'service': 'UserManagementService',
      'action': 'getCurrentUser',
      'args': [username],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users me get response: $respMap');

      if (respMap.containsKey('error')) {
        throw ApiException(400, respMap['error']);
      }
      if (respMap.containsKey('result') && respMap['result'] != null) {
        return UserManagement.fromJson(respMap['result']);
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users me get error: $e');
      rethrow;
    }
  }
}
