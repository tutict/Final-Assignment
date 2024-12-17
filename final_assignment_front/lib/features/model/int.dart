class Int {
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

  Int();

  @override
  String toString() {
    return 'Int[permissionId=$permissionId, permissionName=$permissionName, permissionDescription=$permissionDescription, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, ]';
  }

  Int.fromJson(Map<String, dynamic> json) {
    permissionId = json['permissionId'];
    permissionName = json['permissionName'];
    permissionDescription = json['permissionDescription'];
    createdTime = json['createdTime'];
    modifiedTime = json['modifiedTime'];
    remarks = json['remarks'];
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

  static List<Int> listFromJson(List<dynamic> json) {
    return json.map((value) => Int.fromJson(value)).toList();
  }

  static Map<String, Int> mapFromJson(Map<String, dynamic> json) {
    var map = <String, Int>{};
    if (json.isNotEmpty) {
      json.forEach(
          (String key, dynamic value) => map[key] = Int.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Int-objects as value to a dart map
  static Map<String, List<Int>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<Int>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = Int.listFromJson(value);
      });
    }
    return map;
  }
}
