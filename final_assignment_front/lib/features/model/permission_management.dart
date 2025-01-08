class PermissionManagement {
  /* 权限ID，主键 该字段映射permission_id，使用自动增长方式生成ID */
  int? permissionId;

  /* 权限名称 该字段映射permission_name */
  String? permissionName;

  /* 权限描述 该字段映射permission_description */
  String? permissionDescription;

  /* 创建时间 该字段映射created_time */
  String? createdTime;

  /* 修改时间 该字段映射modified_time */
  String? modifiedTime;

  /* 备注信息 该字段映射remarks */
  String? remarks;

  String  idempotencyKey;

  PermissionManagement({
    required int? permissionId,
    required String? permissionName,
    required String? permissionDescription,
    required String? createdTime,
    required String? modifiedTime,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'PermissionManagement[permissionId=$permissionId, permissionName=$permissionName, permissionDescription=$permissionDescription, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  PermissionManagement.fromJson(Map<String, dynamic> json) {
    permissionId = json['permissionId'];
    permissionName = json['permissionName'];
    permissionDescription = json['permissionDescription'];
    createdTime = json['createdTime'];
    modifiedTime = json['modifiedTime'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (permissionId != null) {
      json['permissionId'] = permissionId;
    }
    if (permissionName != null) {
      json['permissionName'] = permissionName;
    }
    if (permissionDescription != null) {
      json['permissionDescription'] = permissionDescription;
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

  static List<PermissionManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => PermissionManagement.fromJson(value)).toList();
  }

  static Map<String, PermissionManagement> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, PermissionManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = PermissionManagement.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of PermissionManagement-objects as value to a dart map
  static Map<String, List<PermissionManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<PermissionManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = PermissionManagement.listFromJson(value);
      });
    }
    return map;
  }
}
