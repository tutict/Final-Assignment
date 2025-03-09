class SystemLogs {
  /* 日志ID，主键，自增 */
  int? logId;

  /* 日志类型 */
  String? logType;

  /* 日志内容 */
  String? logContent;

  /* 操作时间 */
  DateTime? operationTime;

  /* 操作用户 */
  String? operationUser;

  /* 操作IP地址 */
  String? operationIpAddress;

  /* 备注信息 */
  String? remarks;

  String? idempotencyKey;

  SystemLogs({
    this.logId,
    this.logType,
    this.logContent,
    this.operationTime,
    this.operationUser,
    this.operationIpAddress,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'SystemLogs[logId=$logId, logType=$logType, logContent=$logContent, operationTime=$operationTime, operationUser=$operationUser, operationIpAddress=$operationIpAddress, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory SystemLogs.fromJson(Map<String, dynamic> json) {
    return SystemLogs(
      logId: json['logId'] as int?,
      logType: json['logType'] as String?,
      logContent: json['logContent'] as String?,
      operationTime: json['operationTime'] != null
          ? DateTime.parse(json['operationTime'] as String)
          : null,
      operationUser: json['operationUser'] as String?,
      operationIpAddress: json['operationIpAddress'] as String?,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (logId != null) json['logId'] = logId;
    if (logType != null) json['logType'] = logType;
    if (logContent != null) json['logContent'] = logContent;
    if (operationTime != null) json['operationTime'] = operationTime!.toIso8601String();
    if (operationUser != null) json['operationUser'] = operationUser;
    if (operationIpAddress != null) json['operationIpAddress'] = operationIpAddress;
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  SystemLogs copyWith({
    int? logId,
    String? logType,
    String? logContent,
    DateTime? operationTime,
    String? operationUser,
    String? operationIpAddress,
    String? remarks,
    String? idempotencyKey,
  }) {
    return SystemLogs(
      logId: logId ?? this.logId,
      logType: logType ?? this.logType,
      logContent: logContent ?? this.logContent,
      operationTime: operationTime ?? this.operationTime,
      operationUser: operationUser ?? this.operationUser,
      operationIpAddress: operationIpAddress ?? this.operationIpAddress,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  static List<SystemLogs> listFromJson(List<dynamic> json) {
    return json
        .map((value) => SystemLogs.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SystemLogs> mapFromJson(Map<String, dynamic> json) {
    var map = <String, SystemLogs>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = SystemLogs.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of SystemLogs objects as value to a Dart map
  static Map<String, List<SystemLogs>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<SystemLogs>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = SystemLogs.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}