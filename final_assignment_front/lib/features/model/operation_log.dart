class OperationLog {
  /* 日志ID，主键 使用自动增长方式生成ID */
  int? logId;

  /* 用户ID，记录执行操作的用户 */
  int? userId;

  /* 操作时间，记录操作发生的时间 */
  DateTime? operationTime;

  /* 操作IP地址，记录操作发起的IP地址 */
  String? operationIpAddress;

  /* 操作内容，描述具体的操作行为 */
  String? operationContent;

  /* 操作结果，记录操作的执行结果 */
  String? operationResult;

  /* 备注，用于记录额外的说明信息 */
  String? remarks;

  String? idempotencyKey;

  OperationLog({
    this.logId,
    this.userId,
    this.operationTime,
    this.operationIpAddress,
    this.operationContent,
    this.operationResult,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'OperationLog[logId=$logId, userId=$userId, operationTime=$operationTime, operationIpAddress=$operationIpAddress, operationContent=$operationContent, operationResult=$operationResult, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      logId: json['logId'] as int?,
      userId: json['userId'] as int?,
      operationTime: json['operationTime'] != null
          ? DateTime.parse(json['operationTime'] as String)
          : null,
      operationIpAddress: json['operationIpAddress'] as String?,
      operationContent: json['operationContent'] as String?,
      operationResult: json['operationResult'] as String?,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (logId != null) json['logId'] = logId;
    if (userId != null) json['userId'] = userId;
    if (operationTime != null) json['operationTime'] = operationTime!.toIso8601String();
    if (operationIpAddress != null) json['operationIpAddress'] = operationIpAddress;
    if (operationContent != null) json['operationContent'] = operationContent;
    if (operationResult != null) json['operationResult'] = operationResult;
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  OperationLog copyWith({
    int? logId,
    int? userId,
    DateTime? operationTime,
    String? operationIpAddress,
    String? operationContent,
    String? operationResult,
    String? remarks,
    String? idempotencyKey,
  }) {
    return OperationLog(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      operationTime: operationTime ?? this.operationTime,
      operationIpAddress: operationIpAddress ?? this.operationIpAddress,
      operationContent: operationContent ?? this.operationContent,
      operationResult: operationResult ?? this.operationResult,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  static List<OperationLog> listFromJson(List<dynamic> json) {
    return json
        .map((value) => OperationLog.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, OperationLog> mapFromJson(Map<String, dynamic> json) {
    var map = <String, OperationLog>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = OperationLog.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of OperationLog objects as value to a Dart map
  static Map<String, List<OperationLog>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<OperationLog>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = OperationLog.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}