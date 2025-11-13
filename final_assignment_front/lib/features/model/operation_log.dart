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
      logId: json['logId'] as int?,
      operationType: json['operationType'] as String?,
      operationModule: json['operationModule'] as String?,
      operationFunction: json['operationFunction'] as String?,
      operationContent: json['operationContent'] as String?,
      operationTime: json['operationTime'] != null
          ? DateTime.tryParse(json['operationTime'] as String)
          : null,
      userId: json['userId'] as int?,
      username: json['username'] as String?,
      realName: json['realName'] as String?,
      requestMethod: json['requestMethod'] as String?,
      requestUrl: json['requestUrl'] as String?,
      requestParams: json['requestParams'] as String?,
      requestIp: json['requestIp'] as String?,
      operationResult: json['operationResult'] as String?,
      responseData: json['responseData'] as String?,
      errorMessage: json['errorMessage'] as String?,
      executionTime: json['executionTime'] as int?,
      oldValue: json['oldValue'] as String?,
      newValue: json['newValue'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      remarks: json['remarks'] as String?,
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
