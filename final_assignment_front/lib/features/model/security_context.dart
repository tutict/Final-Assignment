class SecurityContext {
  /* 用户ID，主键，自动增长 */
  int? userId;

  /* 用户姓名 */
  String? name;

  /* 用户名，用于登录 */
  String? username;

  /* 密码，用于登录验证 */
  String? password;

  /* 联系电话 */
  String? contactNumber;

  /* 电子邮件地址 */
  String? email;

  /* 用户类型，区分不同权限的用户 */
  String? userType;

  /* 用户状态，表示用户是否可用或是否被禁用 */
  String? status;

  /* 创建时间，记录用户信息创建的时间 */
  DateTime? createdTime;

  /* 修改时间，记录用户信息最后一次修改的时间 */
  DateTime? modifiedTime;

  /* 备注，用于记录额外的用户信息 */
  String? remarks;

  String? idempotencyKey;

  SecurityContext({
    this.userId,
    this.name,
    this.username,
    this.password,
    this.contactNumber,
    this.email,
    this.userType,
    this.status,
    this.createdTime,
    this.modifiedTime,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'SecurityContext[userId=$userId, name=$name, username=$username, password=$password, contactNumber=$contactNumber, email=$email, userType=$userType, status=$status, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory SecurityContext.fromJson(Map<String, dynamic> json) {
    return SecurityContext(
      userId: json['userId'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      contactNumber: json['contactNumber'] as String?,
      email: json['email'] as String?,
      userType: json['userType'] as String?,
      status: json['status'] as String?,
      createdTime: json['createdTime'] != null
          ? DateTime.parse(json['createdTime'] as String)
          : null,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime'] as String)
          : null,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (userId != null) json['userId'] = userId;
    if (name != null) json['name'] = name;
    if (username != null) json['username'] = username;
    if (password != null) json['password'] = password;
    if (contactNumber != null) json['contactNumber'] = contactNumber;
    if (email != null) json['email'] = email;
    if (userType != null) json['userType'] = userType;
    if (status != null) json['status'] = status;
    if (createdTime != null) json['createdTime'] = createdTime!.toIso8601String();
    if (modifiedTime != null) json['modifiedTime'] = modifiedTime!.toIso8601String();
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  SecurityContext copyWith({
    int? userId,
    String? name,
    String? username,
    String? password,
    String? contactNumber,
    String? email,
    String? userType,
    String? status,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? remarks,
    String? idempotencyKey,
  }) {
    return SecurityContext(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  static List<SecurityContext> listFromJson(List<dynamic> json) {
    return json
        .map((value) => SecurityContext.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SecurityContext> mapFromJson(Map<String, dynamic> json) {
    var map = <String, SecurityContext>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = SecurityContext.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of SecurityContext objects as value to a Dart map
  static Map<String, List<SecurityContext>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<SecurityContext>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = SecurityContext.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}