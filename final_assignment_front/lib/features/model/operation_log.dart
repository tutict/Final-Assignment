import 'package:final_assignment_front/utils/json_parser.dart';

class OperationLog {
  final int? logId;
  final String? operationType;
  final String? operationModule;
  final String? operationFunction;
  final String? operationContent;
  final DateTime? operationTime;
  final int? userId;
  final String? username;
  final String? realName;
  final String? requestMethod;
  final String? requestUrl;
  final String? requestParams;
  final String? requestIp;
  final String? operationResult;
  final String? responseData;
  final String? errorMessage;
  final int? executionTime;
  final String? oldValue;
  final String? newValue;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? remarks;

  const OperationLog({
    this.logId,
    this.operationType,
    this.operationModule,
    this.operationFunction,
    this.operationContent,
    this.operationTime,
    this.userId,
    this.username,
    this.realName,
    this.requestMethod,
    this.requestUrl,
    this.requestParams,
    this.requestIp,
    this.operationResult,
    this.responseData,
    this.errorMessage,
    this.executionTime,
    this.oldValue,
    this.newValue,
    this.createdAt,
    this.deletedAt,
    this.remarks,
  });

  OperationLog copyWith({
    int? logId,
    String? operationType,
    String? operationModule,
    String? operationFunction,
    String? operationContent,
    DateTime? operationTime,
    int? userId,
    String? username,
    String? realName,
    String? requestMethod,
    String? requestUrl,
    String? requestParams,
    String? requestIp,
    String? operationResult,
    String? responseData,
    String? errorMessage,
    int? executionTime,
    String? oldValue,
    String? newValue,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? remarks,
  }) {
    return OperationLog(
      logId: logId ?? this.logId,
      operationType: operationType ?? this.operationType,
      operationModule: operationModule ?? this.operationModule,
      operationFunction: operationFunction ?? this.operationFunction,
      operationContent: operationContent ?? this.operationContent,
      operationTime: operationTime ?? this.operationTime,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      realName: realName ?? this.realName,
      requestMethod: requestMethod ?? this.requestMethod,
      requestUrl: requestUrl ?? this.requestUrl,
      requestParams: requestParams ?? this.requestParams,
      requestIp: requestIp ?? this.requestIp,
      operationResult: operationResult ?? this.operationResult,
      responseData: responseData ?? this.responseData,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      logId: JsonParser.asInt(json['logId']),
      operationType: JsonParser.asString(json['operationType']),
      operationModule: JsonParser.asString(json['operationModule']),
      operationFunction: JsonParser.asString(json['operationFunction']),
      operationContent: JsonParser.asString(json['operationContent']),
      operationTime: JsonParser.asDateTime(json['operationTime']),
      userId: JsonParser.asInt(json['userId']),
      username: JsonParser.asString(json['username']),
      realName: JsonParser.asString(json['realName']),
      requestMethod: JsonParser.asString(json['requestMethod']),
      requestUrl: JsonParser.asString(json['requestUrl']),
      requestParams: JsonParser.asString(json['requestParams']),
      requestIp: JsonParser.asString(json['requestIp']),
      operationResult: JsonParser.asString(json['operationResult']),
      responseData: JsonParser.asString(json['responseData']),
      errorMessage: JsonParser.asString(json['errorMessage']),
      executionTime: JsonParser.asInt(json['executionTime']),
      oldValue: JsonParser.asString(json['oldValue']),
      newValue: JsonParser.asString(json['newValue']),
      createdAt: JsonParser.asDateTime(json['createdAt']),
      deletedAt: JsonParser.asDateTime(json['deletedAt']),
      remarks: JsonParser.asString(json['remarks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'operationType': operationType,
        'operationModule': operationModule,
        'operationFunction': operationFunction,
        'operationContent': operationContent,
        'operationTime': operationTime?.toIso8601String(),
        'userId': userId,
        'username': username,
        'realName': realName,
        'requestMethod': requestMethod,
        'requestUrl': requestUrl,
        'requestParams': requestParams,
        'requestIp': requestIp,
        'operationResult': operationResult,
        'responseData': responseData,
        'errorMessage': errorMessage,
        'executionTime': executionTime,
        'oldValue': oldValue,
        'newValue': newValue,
        'createdAt': createdAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'remarks': remarks,
      };
}
