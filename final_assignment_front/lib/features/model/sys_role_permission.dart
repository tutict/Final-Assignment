class SysRolePermissionModel {
  final int? id;
  final int? roleId;
  final int? permissionId;
  final DateTime? createdTime;
  final String? createdBy;
  final DateTime? deletedAt;

  const SysRolePermissionModel({
    this.id,
    this.roleId,
    this.permissionId,
    this.createdTime,
    this.createdBy,
    this.deletedAt,
  });

  SysRolePermissionModel copyWith({
    int? id,
    int? roleId,
    int? permissionId,
    DateTime? createdTime,
    String? createdBy,
    DateTime? deletedAt,
  }) {
    return SysRolePermissionModel(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      permissionId: permissionId ?? this.permissionId,
      createdTime: createdTime ?? this.createdTime,
      createdBy: createdBy ?? this.createdBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory SysRolePermissionModel.fromJson(Map<String, dynamic> json) {
    return SysRolePermissionModel(
      id: json['id'],
      roleId: json['roleId'],
      permissionId: json['permissionId'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      createdBy: json['createdBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'permissionId': permissionId,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'createdBy': createdBy,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static List<SysRolePermissionModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => SysRolePermissionModel.fromJson(
            value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SysRolePermissionModel> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, SysRolePermissionModel>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = SysRolePermissionModel.fromJson(
            value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SysRolePermissionModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SysRolePermissionModel>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = SysRolePermissionModel.listFromJson(
            value as List<dynamic>);
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
