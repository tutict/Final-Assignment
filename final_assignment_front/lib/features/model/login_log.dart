class LoginLog {
  final int? logId;
  final String? username;
  final DateTime? loginTime;
  final DateTime? logoutTime;
  final String? loginResult;
  final String? failureReason;
  final String? loginIp;
  final String? loginLocation;
  final String? browserType;
  final String? browserVersion;
  final String? osType;
  final String? osVersion;
  final String? deviceType;
  final String? userAgent;
  final String? sessionId;
  final String? token;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? remarks;

  const LoginLog({
    this.logId,
    this.username,
    this.loginTime,
    this.logoutTime,
    this.loginResult,
    this.failureReason,
    this.loginIp,
    this.loginLocation,
    this.browserType,
    this.browserVersion,
    this.osType,
    this.osVersion,
    this.deviceType,
    this.userAgent,
    this.sessionId,
    this.token,
    this.createdAt,
    this.deletedAt,
    this.remarks,
  });

  LoginLog copyWith({
    int? logId,
    String? username,
    DateTime? loginTime,
    DateTime? logoutTime,
    String? loginResult,
    String? failureReason,
    String? loginIp,
    String? loginLocation,
    String? browserType,
    String? browserVersion,
    String? osType,
    String? osVersion,
    String? deviceType,
    String? userAgent,
    String? sessionId,
    String? token,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? remarks,
  }) {
    return LoginLog(
      logId: logId ?? this.logId,
      username: username ?? this.username,
      loginTime: loginTime ?? this.loginTime,
      logoutTime: logoutTime ?? this.logoutTime,
      loginResult: loginResult ?? this.loginResult,
      failureReason: failureReason ?? this.failureReason,
      loginIp: loginIp ?? this.loginIp,
      loginLocation: loginLocation ?? this.loginLocation,
      browserType: browserType ?? this.browserType,
      browserVersion: browserVersion ?? this.browserVersion,
      osType: osType ?? this.osType,
      osVersion: osVersion ?? this.osVersion,
      deviceType: deviceType ?? this.deviceType,
      userAgent: userAgent ?? this.userAgent,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  factory LoginLog.fromJson(Map<String, dynamic> json) {
    return LoginLog(
      logId: json['logId'] as int?,
      username: json['username'] as String?,
      loginTime: json['loginTime'] != null
          ? DateTime.tryParse(json['loginTime'] as String)
          : null,
      logoutTime: json['logoutTime'] != null
          ? DateTime.tryParse(json['logoutTime'] as String)
          : null,
      loginResult: json['loginResult'] as String?,
      failureReason: json['failureReason'] as String?,
      loginIp: json['loginIp'] as String?,
      loginLocation: json['loginLocation'] as String?,
      browserType: json['browserType'] as String?,
      browserVersion: json['browserVersion'] as String?,
      osType: json['osType'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceType: json['deviceType'] as String?,
      userAgent: json['userAgent'] as String?,
      sessionId: json['sessionId'] as String?,
      token: json['token'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'username': username,
      'loginTime': loginTime?.toIso8601String(),
      'logoutTime': logoutTime?.toIso8601String(),
      'loginResult': loginResult,
      'failureReason': failureReason,
      'loginIp': loginIp,
      'loginLocation': loginLocation,
      'browserType': browserType,
      'browserVersion': browserVersion,
      'osType': osType,
      'osVersion': osVersion,
      'deviceType': deviceType,
      'userAgent': userAgent,
      'sessionId': sessionId,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
    };
  }
}
