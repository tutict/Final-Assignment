class RoleManagement {
  int? roleId;
  String? roleName;
  String? roleDescription;
  DateTime? createdTime;
  DateTime? modifiedTime;
  String? remarks;
  String? idempotencyKey;

  RoleManagement({
    this.roleId,
    this.roleName,
    this.roleDescription,
    this.createdTime,
    this.modifiedTime,
    this.remarks,
    this.idempotencyKey,
  });
  @override
  String toString() {
    return 'RoleManagement[roleId=$roleId, roleName=$roleName, roleDescription=$roleDescription, createdTime=$createdTime, modifiedTime=$modifiedTime, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory RoleManagement.fromJson(Map<String, dynamic> json) {
    return RoleManagement(
      roleId: json['roleId'] as int?,
      roleName: json['roleName'] as String?,
      roleDescription: json['roleDescription'] as String?,
      createdTime: json['createdTime'] != null ? DateTime.parse(json['createdTime'] as String) : null,
      modifiedTime: json['modifiedTime'] != null ? DateTime.parse(json['modifiedTime'] as String) : null,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (roleId != null) json['roleId'] = roleId;
    if (roleName != null) json['roleName'] = roleName;
    if (roleDescription != null) json['roleDescription'] = roleDescription;
    if (createdTime != null) json['createdTime'] = createdTime!.toIso8601String();
    if (modifiedTime != null) json['modifiedTime'] = modifiedTime!.toIso8601String();
    if (remarks != null) json['remarks'] = remarks;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  static List<RoleManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => RoleManagement.fromJson(value as Map<String, dynamic>)).toList();
  }

  static Map<String, RoleManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, RoleManagement>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = RoleManagement.fromJson(value));
    }
    return map;
  }

  static Map<String, List<RoleManagement>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<RoleManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) => map[key] = RoleManagement.listFromJson(value));
    }
    return map;
  }
}