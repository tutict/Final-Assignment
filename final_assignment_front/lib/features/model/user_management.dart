class UserManagement {
  final int? userId;
  final String? username;
  final String? password;
  final String? salt;
  final String? realName;
  final String? idCardNumber;
  final String? gender;
  final String? contactNumber;
  final String? email;
  final String? department;
  final String? position;
  final String? employeeNumber;
  final String? status;
  final DateTime? accountExpiryDate;
  final int? loginFailures;
  final DateTime? lastLoginTime;
  final String? lastLoginIp;
  final DateTime? passwordUpdateTime;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;

  const UserManagement({
    this.userId,
    this.username,
    this.password,
    this.salt,
    this.realName,
    this.idCardNumber,
    this.gender,
    this.contactNumber,
    this.email,
    this.department,
    this.position,
    this.employeeNumber,
    this.status,
    this.accountExpiryDate,
    this.loginFailures,
    this.lastLoginTime,
    this.lastLoginIp,
    this.passwordUpdateTime,
    this.createdTime,
    this.modifiedTime,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
  });

  UserManagement copyWith({
    int? userId,
    String? username,
    String? password,
    String? salt,
    String? realName,
    String? idCardNumber,
    String? gender,
    String? contactNumber,
    String? email,
    String? department,
    String? position,
    String? employeeNumber,
    String? status,
    DateTime? accountExpiryDate,
    int? loginFailures,
    DateTime? lastLoginTime,
    String? lastLoginIp,
    DateTime? passwordUpdateTime,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
  }) {
    return UserManagement(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      password: password ?? this.password,
      salt: salt ?? this.salt,
      realName: realName ?? this.realName,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      department: department ?? this.department,
      position: position ?? this.position,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      status: status ?? this.status,
      accountExpiryDate: accountExpiryDate ?? this.accountExpiryDate,
      loginFailures: loginFailures ?? this.loginFailures,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      passwordUpdateTime: passwordUpdateTime ?? this.passwordUpdateTime,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory UserManagement.fromJson(Map<String, dynamic> json) {
    return UserManagement(
      userId: json['userId'] ?? json['id'],
      username: json['username'],
      password: json['password'],
      salt: json['salt'],
      realName: json['realName'] ?? json['name'],
      idCardNumber: json['idCardNumber'],
      gender: json['gender'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      department: json['department'],
      position: json['position'],
      employeeNumber: json['employeeNumber'],
      status: json['status'],
      accountExpiryDate: _parseDateTime(json['accountExpiryDate']),
      loginFailures: json['loginFailures'],
      lastLoginTime: _parseDateTime(json['lastLoginTime']),
      lastLoginIp: json['lastLoginIp'],
      passwordUpdateTime: _parseDateTime(json['passwordUpdateTime']),
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'userId': userId,
      'username': username,
      'password': password,
      'salt': salt,
      'realName': realName,
      'idCardNumber': idCardNumber,
      'gender': gender,
      'contactNumber': contactNumber,
      'email': email,
      'department': department,
      'position': position,
      'employeeNumber': employeeNumber,
      'status': status,
      'accountExpiryDate': accountExpiryDate?.toIso8601String(),
      'loginFailures': loginFailures,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'passwordUpdateTime': passwordUpdateTime?.toIso8601String(),
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'updatedAt': modifiedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'idempotencyKey': idempotencyKey,
    };
    return json;
  }

  @override
  String toString() {
    return 'UserManagement(userId: $userId, username: $username, realName: $realName, status: $status)';
  }

  static List<UserManagement> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => UserManagement.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, UserManagement> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, UserManagement>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = UserManagement.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<UserManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<UserManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            UserManagement.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
