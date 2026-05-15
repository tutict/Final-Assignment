class UserResponse {
  const UserResponse({
    this.userId,
    this.username,
    this.email,
    this.phoneNumber,
    this.roleName,
    this.realName,
    this.gender,
    this.department,
    this.position,
    this.employeeNumber,
    this.status,
    this.createTime,
  });

  final int? userId;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? roleName;
  final String? realName;
  final String? gender;
  final String? department;
  final String? position;
  final String? employeeNumber;
  final String? status;
  final DateTime? createTime;

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: _toInt(json['userId'] ?? json['id']),
      username: json['username'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roleName: json['roleName'] as String?,
      realName: json['realName'] as String?,
      gender: json['gender'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      status: json['status'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'roleName': roleName,
      'realName': realName,
      'gender': gender,
      'department': department,
      'position': position,
      'employeeNumber': employeeNumber,
      'status': status,
      'createTime': createTime?.toIso8601String(),
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
