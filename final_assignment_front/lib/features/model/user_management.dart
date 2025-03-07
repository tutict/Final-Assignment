class UserManagement {
  int? userId;
  String? username;
  String? password;
  String? contactNumber;
  String? email;
  String? status;
  DateTime? createdTime;
  DateTime? modifiedTime;
  String? remarks;
  String? idempotencyKey;

  UserManagement({
    this.userId,
    this.username,
    this.password,
    this.contactNumber,
    this.email,
    this.status,
    this.createdTime,
    this.modifiedTime,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'UserManagement[userId=$userId, username=$username, password=$password, contactNumber=$contactNumber, email=$email, status=$status, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory UserManagement.fromJson(Map<String, dynamic> json) {
    return UserManagement(
      userId: json['userId'] as int?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      contactNumber: json['contactNumber'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String?,
      createdTime: json['createdTime'] != null ? DateTime.parse(json['createdTime'] as String) : null,
      modifiedTime: json['modifiedTime'] != null ? DateTime.parse(json['modifiedTime'] as String) : null,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (userId != null) json['userId'] = userId;
    if (username != null) json['username'] = username;
    if (password != null) json['password'] = password;
    if (contactNumber != null) json['contactNumber'] = contactNumber;
    if (email != null) json['email'] = email;
    if (status != null) json['status'] = status;
    if (createdTime != null) json['createdTime'] = createdTime!.toIso8601String();
    if (modifiedTime != null) json['modifiedTime'] = modifiedTime!.toIso8601String();
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  static List<UserManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => UserManagement.fromJson(value as Map<String, dynamic>)).toList();
  }

  static Map<String, UserManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, UserManagement>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = UserManagement.fromJson(value));
    }
    return map;
  }

  static Map<String, List<UserManagement>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<UserManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = UserManagement.listFromJson(value));
    }
    return map;
  }
}