class LoginLog {
  /* 日志ID，主键，自增 */
  int? logId;

  /* 登录用户名 */
  String? username;

  /* 登录IP地址 */
  String? loginIpAddress;

  /* 登录时间 */
  String? loginTime;

  /* 登录结果 */
  String? loginResult;

  /* 浏览器类型 */
  String? browserType;

  /* 操作系统版本 */
  String? osVersion;

  /* 备注信息 */
  String? remarks;

  String idempotencyKey;

  LoginLog({
    required int? logId,
    required String? username,
    required String? loginIpAddress,
    required String? loginTime,
    required String? loginResult,
    required String? browserType,
    required String? osVersion,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'LoginLog[logId=$logId, username=$username, loginIpAddress=$loginIpAddress, loginTime=$loginTime, loginResult=$loginResult, browserType=$browserType, osVersion=$osVersion, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  LoginLog.fromJson(Map<String, dynamic> json) {
    logId = json['logId'];
    username = json['username'];
    loginIpAddress = json['loginIpAddress'];
    loginTime = json['loginTime'];
    loginResult = json['loginResult'];
    browserType = json['browserType'];
    osVersion = json['osVersion'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (logId != null) {
      json['logId'] = logId;
    }
    if (username != null) {
      json['username'] = username;
    }
    if (loginIpAddress != null) {
      json['loginIpAddress'] = loginIpAddress;
    }
    if (loginTime != null) {
      json['loginTime'] = loginTime;
    }
    if (loginResult != null) {
      json['loginResult'] = loginResult;
    }
    if (browserType != null) {
      json['browserType'] = browserType;
    }
    if (osVersion != null) {
      json['osVersion'] = osVersion;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<LoginLog> listFromJson(List<dynamic> json) {
    return json.map((value) => LoginLog.fromJson(value)).toList();
  }

  static Map<String, LoginLog> mapFromJson(Map<String, dynamic> json) {
    var map = <String, LoginLog>{};
    if (json.isNotEmpty) {
      json.forEach(
          (String key, dynamic value) => map[key] = LoginLog.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of LoginLog-objects as value to a dart map
  static Map<String, List<LoginLog>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<LoginLog>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = LoginLog.listFromJson(value);
      });
    }
    return map;
  }
}
