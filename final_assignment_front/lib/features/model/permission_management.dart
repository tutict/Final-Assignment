class PermissionManagement {
  final int? permissionId;
  final int? parentId;
  final String? permissionCode;
  final String? permissionName;
  final String? permissionType;
  final String? permissionDescription;
  final String? menuPath;
  final String? menuIcon;
  final String? component;
  final String? apiPath;
  final String? apiMethod;
  final bool? isVisible;
  final bool? isExternal;
  final int? sortOrder;
  final String? status;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;

  const PermissionManagement({
    this.permissionId,
    this.parentId,
    this.permissionCode,
    this.permissionName,
    this.permissionType,
    this.permissionDescription,
    this.menuPath,
    this.menuIcon,
    this.component,
    this.apiPath,
    this.apiMethod,
    this.isVisible,
    this.isExternal,
    this.sortOrder,
    this.status,
    this.createdTime,
    this.modifiedTime,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
  });

  PermissionManagement copyWith({
    int? permissionId,
    int? parentId,
    String? permissionCode,
    String? permissionName,
    String? permissionType,
    String? permissionDescription,
    String? menuPath,
    String? menuIcon,
    String? component,
    String? apiPath,
    String? apiMethod,
    bool? isVisible,
    bool? isExternal,
    int? sortOrder,
    String? status,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
  }) {
    return PermissionManagement(
      permissionId: permissionId ?? this.permissionId,
      parentId: parentId ?? this.parentId,
      permissionCode: permissionCode ?? this.permissionCode,
      permissionName: permissionName ?? this.permissionName,
      permissionType: permissionType ?? this.permissionType,
      permissionDescription:
          permissionDescription ?? this.permissionDescription,
      menuPath: menuPath ?? this.menuPath,
      menuIcon: menuIcon ?? this.menuIcon,
      component: component ?? this.component,
      apiPath: apiPath ?? this.apiPath,
      apiMethod: apiMethod ?? this.apiMethod,
      isVisible: isVisible ?? this.isVisible,
      isExternal: isExternal ?? this.isExternal,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory PermissionManagement.fromJson(Map<String, dynamic> json) {
    return PermissionManagement(
      permissionId: json['permissionId'],
      parentId: json['parentId'],
      permissionCode: json['permissionCode'],
      permissionName: json['permissionName'],
      permissionType: json['permissionType'],
      permissionDescription: json['permissionDescription'],
      menuPath: json['menuPath'],
      menuIcon: json['menuIcon'],
      component: json['component'],
      apiPath: json['apiPath'],
      apiMethod: json['apiMethod'],
      isVisible: _parseBool(json['isVisible']),
      isExternal: _parseBool(json['isExternal']),
      sortOrder: json['sortOrder'],
      status: json['status'],
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
      'permissionId': permissionId,
      'parentId': parentId,
      'permissionCode': permissionCode,
      'permissionName': permissionName,
      'permissionType': permissionType,
      'permissionDescription': permissionDescription,
      'menuPath': menuPath,
      'menuIcon': menuIcon,
      'component': component,
      'apiPath': apiPath,
      'apiMethod': apiMethod,
      'isVisible': isVisible,
      'isExternal': isExternal,
      'sortOrder': sortOrder,
      'status': status,
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
    return 'PermissionManagement(permissionId: $permissionId, code: $permissionCode, name: $permissionName)';
  }

  static List<PermissionManagement> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) =>
            PermissionManagement.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, PermissionManagement> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, PermissionManagement>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            PermissionManagement.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<PermissionManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<PermissionManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            PermissionManagement.listFromJson(value as List<dynamic>);
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

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == '1' || lower == 'true') return true;
      if (lower == '0' || lower == 'false') return false;
    }
    return null;
  }
}
