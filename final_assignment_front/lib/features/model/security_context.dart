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
  String? createdTime;

  /* 修改时间，记录用户信息最后一次修改的时间 */
  String? modifiedTime;

  /* 备注，用于记录额外的用户信息 */
  String? remarks;

  String idempotencyKey;

  SecurityContext({
    required int? userId,
    required String? name,
    required String? username,
    required String? password,
    required String? contactNumber,
    required String? email,
    required String? userType,
    required String? status,
    required String? createdTime,
    required String? modifiedTime,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'SecurityContext[userId=$userId, name=$name, username=$username, password=$password, contactNumber=$contactNumber, email=$email, userType=$userType, status=$status, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  SecurityContext.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    name = json['name'];
    username = json['username'];
    password = json['password'];
    contactNumber = json['contactNumber'];
    email = json['email'];
    userType = json['userType'];
    status = json['status'];
    createdTime = json['createdTime'];
    modifiedTime = json['modifiedTime'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (userId != null) {
      json['userId'] = userId;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (username != null) {
      json['username'] = username;
    }
    if (password != null) {
      json['password'] = password;
    }
    if (contactNumber != null) {
      json['contactNumber'] = contactNumber;
    }
    if (email != null) {
      json['email'] = email;
    }
    if (userType != null) {
      json['userType'] = userType;
    }
    if (status != null) {
      json['status'] = status;
    }
    if (createdTime != null) {
      json['createdTime'] = createdTime;
    }
    if (modifiedTime != null) {
      json['modifiedTime'] = modifiedTime;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<SecurityContext> listFromJson(List<dynamic> json) {
    return json.map((value) => SecurityContext.fromJson(value)).toList();
  }

  static Map<String, SecurityContext> mapFromJson(Map<String, dynamic> json) {
    var map = <String, SecurityContext>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = SecurityContext.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of SecurityContext-objects as value to a dart map
  static Map<String, List<SecurityContext>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<SecurityContext>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = SecurityContext.listFromJson(value);
      });
    }
    return map;
  }
}
