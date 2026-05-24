import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class ProgressControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  ProgressControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<ProgressItem> createProgressItem({
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) {
    return requestObject(
      'POST',
      '/api/progress',
      ProgressItem.fromJson,
      body: progressItem.toJson(),
      headers: headers ?? const {},
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<List<ProgressItem>> listProgressItems({
    Map<String, String>? headers,
  }) {
    return requestList(
      'GET',
      '/api/progress',
      ProgressItem.fromJson,
      headers: headers ?? const {},
    );
  }

  Future<List<ProgressItem>> listProgressItemsByUsername({
    required String username,
    Map<String, String>? headers,
  }) {
    return requestList(
      'GET',
      '/api/progress',
      ProgressItem.fromJson,
      queryParams: [QueryParam('username', username)],
      headers: headers ?? const {},
    );
  }

  Future<ProgressItem> updateProgressItemStatus({
    required int progressId,
    required String newStatus,
    Map<String, String>? headers,
  }) async {
    final progressBody = await requestMap(
      'GET',
      '/api/progress/$progressId',
      headers: headers ?? const {},
    );
    progressBody['businessStatus'] = newStatus;
    progressBody['status'] = newStatus;

    return requestObject(
      'PUT',
      '/api/progress/$progressId',
      ProgressItem.fromJson,
      body: progressBody,
      headers: headers ?? const {},
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<ProgressItem> updateProgressItem({
    required int progressId,
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) {
    return requestObject(
      'PUT',
      '/api/progress/$progressId',
      ProgressItem.fromJson,
      body: progressItem.toJson(),
      headers: headers ?? const {},
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<void> deleteProgressItem({
    required int progressId,
    Map<String, String>? headers,
  }) {
    return requestVoid(
      'DELETE',
      '/api/progress/$progressId',
      headers: headers ?? const {},
    );
  }

  Future<List<ProgressItem>> listProgressItemsByStatus({
    required String status,
    Map<String, String>? headers,
  }) {
    return requestList(
      'GET',
      '/api/progress/status',
      ProgressItem.fromJson,
      queryParams: [QueryParam('status', status)],
      headers: headers ?? const {},
    );
  }

  Future<List<ProgressItem>> searchProgressItemsByTimeRange({
    required String startTime,
    required String endTime,
    Map<String, String>? headers,
  }) {
    return requestList(
      'GET',
      '/api/progress/timeRange',
      ProgressItem.fromJson,
      queryParams: [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
      ],
      headers: headers ?? const {},
    );
  }

  Future<List<Object>?> eventbusProgressUsernameGet({
    required String username,
  }) {
    return sendWsObjectList(
      service: 'ProgressItemService',
      action: 'getProgressByUsername',
      args: [username],
    );
  }

  Future<List<Object>?> eventbusProgressGet() {
    return sendWsObjectList(
      service: 'ProgressItemService',
      action: 'getAllProgress',
    );
  }

  Future<List<Object>?> eventbusProgressStatusStatusGet({
    required String status,
  }) {
    return sendWsObjectList(
      service: 'ProgressItemService',
      action: 'getProgressByStatus',
      args: [status],
    );
  }

  Future<List<Object>?> eventbusProgressTimeRangeGet({
    required String startTime,
    required String endTime,
  }) {
    return sendWsObjectList(
      service: 'ProgressItemService',
      action: 'getProgressByTimeRange',
      args: [startTime, endTime],
    );
  }

  Future<Object?> eventbusProgressProgressIdDelete({
    required int progressId,
  }) {
    return sendWs(
      service: 'ProgressItemService',
      action: 'deleteProgress',
      args: [progressId],
    );
  }

  Future<Object?> eventbusProgressProgressIdStatusPut({
    required int progressId,
    required String newStatus,
  }) {
    return sendWs(
      service: 'ProgressItemService',
      action: 'updateProgressStatus',
      args: [progressId, newStatus],
    );
  }

  Future<Object?> eventbusProgressPost({
    required ProgressItem progressItem,
  }) {
    return sendWs(
      service: 'ProgressItemService',
      action: 'createProgress',
      args: [progressItem.toJson()],
    );
  }
}
