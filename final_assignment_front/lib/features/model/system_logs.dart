class SystemLogs {
  /* 日志ID，主键，自增 */
  int? logId;

  /* 日志类型 */
  String? logType;

  /* 日志内容 */
  String? logContent;

  /* 操作时间 */
  String? operationTime;

  /* 操作用户 */
  String? operationUser;

  /* 操作IP地址 */
  String? operationIpAddress;

  /* 备注信息 */
  String? remarks;

  String? idempotencyKey;

  SystemLogs({
    required int? logId,
    required String? logType,
    required String? logContent,
    required String? operationTime,
    required String? operationUser,
    required String? operationIpAddress,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'SystemLogs[logId=$logId, logType=$logType, logContent=$logContent, operationTime=$operationTime, operationUser=$operationUser, operationIpAddress=$operationIpAddress, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  SystemLogs.fromJson(Map<String, dynamic> json) {
    logId = json['logId'];
    logType = json['logType'];
    logContent = json['logContent'];
    operationTime = json['operationTime'];
    operationUser = json['operationUser'];
    operationIpAddress = json['operationIpAddress'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (logId != null) {
      json['logId'] = logId;
    }
    if (logType != null) {
      json['logType'] = logType;
    }
    if (logContent != null) {
      json['logContent'] = logContent;
    }
    if (operationTime != null) {
      json['operationTime'] = operationTime;
    }
    if (operationUser != null) {
      json['operationUser'] = operationUser;
    }
    if (operationIpAddress != null) {
      json['operationIpAddress'] = operationIpAddress;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<SystemLogs> listFromJson(List<dynamic> json) {
    return json.map((value) => SystemLogs.fromJson(value)).toList();
  }

  static Map<String, SystemLogs> mapFromJson(Map<String, dynamic> json) {
    var map = <String, SystemLogs>{};
    if (json.isNotEmpty) {
      json.forEach(
          (String key, dynamic value) => map[key] = SystemLogs.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of SystemLogs-objects as value to a dart map
  static Map<String, List<SystemLogs>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<SystemLogs>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = SystemLogs.listFromJson(value);
      });
    }
    return map;
  }
}
