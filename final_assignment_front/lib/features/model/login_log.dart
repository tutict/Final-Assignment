class LoginLog {
  int? logId;
  String? username;
  String? loginIpAddress;
  DateTime? loginTime;
  String? loginResult;
  String? browserType;
  String? osVersion;
  String? remarks;
  String? idempotencyKey;

  LoginLog({
    this.logId,
    this.username,
    this.loginIpAddress,
    this.loginTime,
    this.loginResult,
    this.browserType,
    this.osVersion,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'LoginLog[logId=$logId, username=$username, loginIpAddress=$loginIpAddress, loginTime=$loginTime, loginResult=$loginResult, browserType=$browserType, osVersion=$osVersion, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory LoginLog.fromJson(Map<String, dynamic> json) {
    return LoginLog(
      logId: json['logId'] as int?,
      username: json['username'] as String?,
      loginIpAddress: json['loginIpAddress'] as String?,
      loginTime: json['loginTime'] != null ? DateTime.parse(json['loginTime'] as String) : null,
      loginResult: json['loginResult'] as String?,
      browserType: json['browserType'] as String?,
      osVersion: json['osVersion'] as String?,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (logId != null) json['logId'] = logId;
    if (username != null) json['username'] = username;
    if (loginIpAddress != null) json['loginIpAddress'] = loginIpAddress;
    if (loginTime != null) json['loginTime'] = loginTime!.toIso8601String();
    if (loginResult != null) json['loginResult'] = loginResult;
    if (browserType != null) json['browserType'] = browserType;
    if (osVersion != null) json['osVersion'] = osVersion;
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  static List<LoginLog> listFromJson(List<dynamic> json) {
    return json.map((value) => LoginLog.fromJson(value as Map<String, dynamic>)).toList();
  }

  static Map<String, LoginLog> mapFromJson(Map<String, dynamic> json) {
    var map = <String, LoginLog>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = LoginLog.fromJson(value));
    }
    return map;
  }

  static Map<String, List<LoginLog>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<LoginLog>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = LoginLog.listFromJson(value));
    }
    return map;
  }
}