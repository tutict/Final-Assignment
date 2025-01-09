class OperationLog {
  /* 日志ID，主键 使用自动增长方式生成ID */
  int? logId;

  /* 用户ID，记录执行操作的用户 */
  int? userId;

  /* 操作时间，记录操作发生的时间 */
  String? operationTime;

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
    required int? logId,
    required int? userId,
    required String? operationTime,
    required String? operationIpAddress,
    required String? operationContent,
    required String? operationResult,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'OperationLog[logId=$logId, userId=$userId, operationTime=$operationTime, operationIpAddress=$operationIpAddress, operationContent=$operationContent, operationResult=$operationResult, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  OperationLog.fromJson
      (Map<String, dynamic> json) {
    logId = json['logId'];
    userId = json['userId'];
    operationTime = json['operationTime'];
    operationIpAddress = json['operationIpAddress'];
    operationContent = json['operationContent'];
    operationResult = json['operationResult'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (logId != null) {
      json['logId'] = logId;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    if (operationTime != null) {
      json['operationTime'] = operationTime;
    }
    if (operationIpAddress != null) {
      json['operationIpAddress'] = operationIpAddress;
    }
    if (operationContent != null) {
      json['operationContent'] = operationContent;
    }
    if (operationResult != null) {
      json['operationResult'] = operationResult;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<OperationLog> listFromJson(List<dynamic> json) {
    return json.map((value) => OperationLog.fromJson(value)).toList();
  }

  static Map<String, OperationLog> mapFromJson(Map<String, dynamic> json) {
    var map = <String, OperationLog>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = OperationLog.fromJson(value));
    }
    return map;
  }

// maps a json object with a list of OperationLog-objects as value to a dart map
  static Map<String, List<OperationLog>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<OperationLog>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = OperationLog.listFromJson(value);
      });
    }
    return map;
  }
}
