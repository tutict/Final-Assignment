class PermissionManagement {
  /* 权限ID，主键 该字段映射permission_id，使用自动增长方式生成ID */
  int? permissionId;

  /* 权限名称 该字段映射permission_name */
  String? permissionName;

  /* 权限描述 该字段映射permission_description */
  String? permissionDescription;

  /* 创建时间 该字段映射created_time */
  DateTime? createdTime;

  /* 修改时间 该字段映射modified_time */
  DateTime? modifiedTime;

  /* 备注信息 该字段映射remarks */
  String? remarks;

  String? idempotencyKey;

  PermissionManagement({
    this.permissionId,
    this.permissionName,
    this.permissionDescription,
    this.createdTime,
    this.modifiedTime,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'PermissionManagement[permissionId=$permissionId, permissionName=$permissionName, permissionDescription=$permissionDescription, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory PermissionManagement.fromJson(Map<String, dynamic> json) {
    return PermissionManagement(
      permissionId: json['permissionId'] as int?,
      permissionName: json['permissionName'] as String?,
      permissionDescription: json['permissionDescription'] as String?,
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
    if (permissionId != null) json['permissionId'] = permissionId;
    if (permissionName != null) json['permissionName'] = permissionName;
    if (permissionDescription != null) {
      json['permissionDescription'] = permissionDescription;
    }
    if (createdTime != null) {
      json['createdTime'] = createdTime!.toIso8601String();
    }
    if (modifiedTime != null) {
      json['modifiedTime'] = modifiedTime!.toIso8601String();
    }
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  PermissionManagement copyWith({
    int? permissionId,
    String? permissionName,
    String? permissionDescription,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? remarks,
    String? idempotencyKey,
  }) {
    return PermissionManagement(
      permissionId: permissionId ?? this.permissionId,
      permissionName: permissionName ?? this.permissionName,
      permissionDescription:
          permissionDescription ?? this.permissionDescription,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  static List<PermissionManagement> listFromJson(List<dynamic> json) {
    return json
        .map((value) =>
            PermissionManagement.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, PermissionManagement> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, PermissionManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] =
          PermissionManagement.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of PermissionManagement objects as value to a Dart map
  static Map<String, List<PermissionManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<PermissionManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = PermissionManagement.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}
