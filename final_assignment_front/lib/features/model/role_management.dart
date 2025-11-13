class RoleManagement {
  final int? roleId;
  final String? roleCode;
  final String? roleName;
  final String? roleType;
  final String? roleDescription;
  final String? dataScope;
  final String? status;
  final int? sortOrder;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;

  const RoleManagement({
    this.roleId,
    this.roleCode,
    this.roleName,
    this.roleType,
    this.roleDescription,
    this.dataScope,
    this.status,
    this.sortOrder,
    this.createdTime,
    this.modifiedTime,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
  });

  RoleManagement copyWith({
    int? roleId,
    String? roleCode,
    String? roleName,
    String? roleType,
    String? roleDescription,
    String? dataScope,
    String? status,
    int? sortOrder,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
  }) {
    return RoleManagement(
      roleId: roleId ?? this.roleId,
      roleCode: roleCode ?? this.roleCode,
      roleName: roleName ?? this.roleName,
      roleType: roleType ?? this.roleType,
      roleDescription: roleDescription ?? this.roleDescription,
      dataScope: dataScope ?? this.dataScope,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory RoleManagement.fromJson(Map<String, dynamic> json) {
    return RoleManagement(
      roleId: json['roleId'],
      roleCode: json['roleCode'],
      roleName: json['roleName'],
      roleType: json['roleType'],
      roleDescription: json['roleDescription'],
      dataScope: json['dataScope'],
      status: json['status'],
      sortOrder: json['sortOrder'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleCode': roleCode,
      'roleName': roleName,
      'roleType': roleType,
      'roleDescription': roleDescription,
      'dataScope': dataScope,
      'status': status,
      'sortOrder': sortOrder,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'updatedAt': modifiedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'idempotencyKey': idempotencyKey,
    };
  }

  @override
  String toString() {
    return 'RoleManagement(roleId: $roleId, roleCode: $roleCode, roleName: $roleName, status: $status)';
  }

  static List<RoleManagement> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => RoleManagement.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, RoleManagement> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, RoleManagement>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = RoleManagement.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<RoleManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<RoleManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            RoleManagement.listFromJson(value as List<dynamic>);
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
