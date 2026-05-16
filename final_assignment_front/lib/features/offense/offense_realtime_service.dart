import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:get/get.dart';

final ApiClient defaultOffenseRealtimeApiClient = ApiClient();

class OffenseRealtimeService extends GetxService {
  OffenseRealtimeService({ApiClient? apiClient})
      : apiClient = apiClient ?? defaultOffenseRealtimeApiClient;

  final ApiClient apiClient;

  Future<void> connect({
    String path = '/eventbus/websocket',
    List<QueryParam> params = const [],
  }) {
    return apiClient.connectWs(path, params: params);
  }

  void close() {
    apiClient.closeWebSocket();
  }

  Future<void> eventbusOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'checkAndInsertIdempotency',
      'args': [idempotencyKey, offenseInformation.toJson(), 'create'],
    });
    _throwIfError(
      respMap,
      duplicateMessage:
          'Duplicate request detected with idempotencyKey: $idempotencyKey',
    );
  }

  Future<OffenseInformation?> eventbusOffensesOffenseIdGet({
    required int offenseId,
  }) async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'getOffenseByOffenseId',
      'args': [offenseId],
    });
    final error = _errorText(respMap);
    if (error != null) {
      if (error.contains('not found')) {
        return null;
      }
      throw AppException.http(400, error);
    }

    final result = respMap['result'];
    if (result == null) {
      return null;
    }
    return OffenseInformation.fromJson(_asJsonMap(result));
  }

  Future<List<OffenseInformation>> eventbusOffensesGet() async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'getOffensesInformation',
      'args': [],
    });
    _throwIfError(respMap);
    return _parseOffenseList(respMap['result']);
  }

  Future<OffenseInformation?> eventbusOffensesOffenseIdPut({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'checkAndInsertIdempotency',
      'args': [idempotencyKey, offenseInformation.toJson(), 'update'],
    });
    _throwIfError(
      respMap,
      notFoundMessage: 'Offense not found with ID: $offenseId',
      duplicateMessage:
          'Duplicate request detected with idempotencyKey: $idempotencyKey',
    );

    final result = respMap['result'];
    if (result == null) {
      return null;
    }
    return OffenseInformation.fromJson(_asJsonMap(result));
  }

  Future<void> eventbusOffensesOffenseIdDelete({
    required int offenseId,
  }) async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'deleteOffense',
      'args': [offenseId],
    });
    _throwIfError(
      respMap,
      notFoundMessage: 'Offense not found with ID: $offenseId',
      unauthorizedMessage: 'Unauthorized: Only ADMIN can delete offenses',
    );
  }

  Future<List<OffenseInformation>> eventbusOffensesTimeRangeGet({
    String startTime = '1970-01-01T00:00:00',
    String endTime = '2100-01-01T23:59:59',
  }) async {
    final respMap = await apiClient.sendWsMessage({
      'service': 'OffenseRecordService',
      'action': 'getOffensesByTimeRange',
      'args': [startTime, endTime],
    });
    _throwIfError(respMap);
    return _parseOffenseList(respMap['result']);
  }

  List<OffenseInformation> _parseOffenseList(dynamic value) {
    if (value is! List) {
      return <OffenseInformation>[];
    }
    return value
        .map((json) => OffenseInformation.fromJson(_asJsonMap(json)))
        .toList();
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw AppException.http(400, 'WebSocket result is not a JSON object');
  }

  void _throwIfError(
    Map<String, dynamic> respMap, {
    String? notFoundMessage,
    String? duplicateMessage,
    String? unauthorizedMessage,
  }) {
    final error = _errorText(respMap);
    if (error == null) {
      return;
    }
    if (notFoundMessage != null && error.contains('not found')) {
      throw AppException.http(404, notFoundMessage);
    }
    if (duplicateMessage != null && error.contains('Duplicate')) {
      throw AppException.http(409, duplicateMessage);
    }
    if (unauthorizedMessage != null && error.contains('Unauthorized')) {
      throw AppException.http(403, unauthorizedMessage);
    }
    throw AppException.http(400, error);
  }

  String? _errorText(Map<String, dynamic> respMap) {
    final error = respMap['error'];
    if (error == null) {
      return null;
    }
    final text = error.toString();
    return text.isEmpty ? null : text;
  }
}
