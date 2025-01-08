class RoleManagement {
  /* 角色ID 该字段表示角色的唯一标识符，采用自动增长的方式生成 */
  int? roleId;

  /* 角色名称 该字段表示角色的名称 */
  String? roleName;

  /* 角色描述 该字段用于描述角色的详细信息 */
  String? roleDescription;

  /* 创建时间 该字段记录角色创建的时间 */
  String? createdTime;

  /* 修改时间 该字段记录角色最后修改的时间 */
  String? modifiedTime;

  /* 备注 该字段用于记录角色相关的额外信息或备注 */
  String? remarks;

  String idempotencyKey;

  RoleManagement({
    required int? roleId,
    required String? roleName,
    required String? roleDescription,
    required String? createdTime,
    required String? modifiedTime,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'RoleManagement[roleId=$roleId, roleName=$roleName, roleDescription=$roleDescription, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  RoleManagement.fromJson(Map<String, dynamic> json) {
    roleId = json['roleId'];
    roleName = json['roleName'];
    roleDescription = json['roleDescription'];
    createdTime = json['createdTime'];
    modifiedTime = json['modifiedTime'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (roleId != null) {
      json['roleId'] = roleId;
    }
    if (roleName != null) {
      json['roleName'] = roleName;
    }
    if (roleDescription != null) {
      json['roleDescription'] = roleDescription;
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

  static List<RoleManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => RoleManagement.fromJson(value)).toList();
  }

  static Map<String, RoleManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, RoleManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = RoleManagement.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of RoleManagement-objects as value to a dart map
  static Map<String, List<RoleManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<RoleManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = RoleManagement.listFromJson(value);
      });
    }
    return map;
  }
}
