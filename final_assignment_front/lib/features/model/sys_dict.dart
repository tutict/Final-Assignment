class SysDictModel {
  final int? dictId;
  final int? parentId;
  final String? dictType;
  final String? dictCode;
  final String? dictLabel;
  final String? dictValue;
  final String? dictDescription;
  final String? cssClass;
  final String? listClass;
  final bool? isDefault;
  final bool? isFixed;
  final String? status;
  final int? sortOrder;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  const SysDictModel({
    this.dictId,
    this.parentId,
    this.dictType,
    this.dictCode,
    this.dictLabel,
    this.dictValue,
    this.dictDescription,
    this.cssClass,
    this.listClass,
    this.isDefault,
    this.isFixed,
    this.status,
    this.sortOrder,
    this.createdTime,
    this.modifiedTime,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
  });

  SysDictModel copyWith({
    int? dictId,
    int? parentId,
    String? dictType,
    String? dictCode,
    String? dictLabel,
    String? dictValue,
    String? dictDescription,
    String? cssClass,
    String? listClass,
    bool? isDefault,
    bool? isFixed,
    String? status,
    int? sortOrder,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
  }) {
    return SysDictModel(
      dictId: dictId ?? this.dictId,
      parentId: parentId ?? this.parentId,
      dictType: dictType ?? this.dictType,
      dictCode: dictCode ?? this.dictCode,
      dictLabel: dictLabel ?? this.dictLabel,
      dictValue: dictValue ?? this.dictValue,
      dictDescription: dictDescription ?? this.dictDescription,
      cssClass: cssClass ?? this.cssClass,
      listClass: listClass ?? this.listClass,
      isDefault: isDefault ?? this.isDefault,
      isFixed: isFixed ?? this.isFixed,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  factory SysDictModel.fromJson(Map<String, dynamic> json) {
    return SysDictModel(
      dictId: json['dictId'],
      parentId: json['parentId'],
      dictType: json['dictType'],
      dictCode: json['dictCode'],
      dictLabel: json['dictLabel'],
      dictValue: json['dictValue'],
      dictDescription: json['dictDescription'],
      cssClass: json['cssClass'],
      listClass: json['listClass'],
      isDefault: _parseBool(json['isDefault']),
      isFixed: _parseBool(json['isFixed']),
      status: json['status'],
      sortOrder: json['sortOrder'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dictId': dictId,
      'parentId': parentId,
      'dictType': dictType,
      'dictCode': dictCode,
      'dictLabel': dictLabel,
      'dictValue': dictValue,
      'dictDescription': dictDescription,
      'cssClass': cssClass,
      'listClass': listClass,
      'isDefault': isDefault,
      'isFixed': isFixed,
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
    };
  }

  static List<SysDictModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => SysDictModel.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SysDictModel> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, SysDictModel>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SysDictModel.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SysDictModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SysDictModel>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SysDictModel.listFromJson(value as List<dynamic>);
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
