class SysUserRoleModel {
  final int? id;
  final int? userId;
  final int? roleId;
  final DateTime? createdTime;
  final String? createdBy;
  final DateTime? deletedAt;

  const SysUserRoleModel({
    this.id,
    this.userId,
    this.roleId,
    this.createdTime,
    this.createdBy,
    this.deletedAt,
  });

  SysUserRoleModel copyWith({
    int? id,
    int? userId,
    int? roleId,
    DateTime? createdTime,
    String? createdBy,
    DateTime? deletedAt,
  }) {
    return SysUserRoleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      createdTime: createdTime ?? this.createdTime,
      createdBy: createdBy ?? this.createdBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory SysUserRoleModel.fromJson(Map<String, dynamic> json) {
    return SysUserRoleModel(
      id: json['id'],
      userId: json['userId'],
      roleId: json['roleId'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      createdBy: json['createdBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'roleId': roleId,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'createdBy': createdBy,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static List<SysUserRoleModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) =>
            SysUserRoleModel.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SysUserRoleModel> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, SysUserRoleModel>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SysUserRoleModel.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SysUserRoleModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SysUserRoleModel>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SysUserRoleModel.listFromJson(value as List<dynamic>);
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
