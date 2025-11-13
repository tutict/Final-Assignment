class SystemSettings {
  final int? settingId;
  final String? settingKey;
  final String? settingValue;
  final String? settingType;
  final String? category;
  final String? description;
  final bool? isEncrypted;
  final bool? isEditable;
  final int? sortOrder;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;

  // 兼容旧版 API 的聚合字段
  final String? systemName;
  final String? systemVersion;
  final String? systemDescription;
  final String? copyrightInfo;
  final String? storagePath;
  final int? loginTimeout;
  final int? sessionTimeout;
  final String? dateFormat;
  final int? pageSize;
  final String? smtpServer;
  final String? emailAccount;
  final String? emailPassword;

  const SystemSettings({
    this.settingId,
    this.settingKey,
    this.settingValue,
    this.settingType,
    this.category,
    this.description,
    this.isEncrypted,
    this.isEditable,
    this.sortOrder,
    this.createdTime,
    this.modifiedTime,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
    this.systemName,
    this.systemVersion,
    this.systemDescription,
    this.copyrightInfo,
    this.storagePath,
    this.loginTimeout,
    this.sessionTimeout,
    this.dateFormat,
    this.pageSize,
    this.smtpServer,
    this.emailAccount,
    this.emailPassword,
  });

  SystemSettings copyWith({
    int? settingId,
    String? settingKey,
    String? settingValue,
    String? settingType,
    String? category,
    String? description,
    bool? isEncrypted,
    bool? isEditable,
    int? sortOrder,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
    String? systemName,
    String? systemVersion,
    String? systemDescription,
    String? copyrightInfo,
    String? storagePath,
    int? loginTimeout,
    int? sessionTimeout,
    String? dateFormat,
    int? pageSize,
    String? smtpServer,
    String? emailAccount,
    String? emailPassword,
  }) {
    return SystemSettings(
      settingId: settingId ?? this.settingId,
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      settingType: settingType ?? this.settingType,
      category: category ?? this.category,
      description: description ?? this.description,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isEditable: isEditable ?? this.isEditable,
      sortOrder: sortOrder ?? this.sortOrder,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      systemName: systemName ?? this.systemName,
      systemVersion: systemVersion ?? this.systemVersion,
      systemDescription: systemDescription ?? this.systemDescription,
      copyrightInfo: copyrightInfo ?? this.copyrightInfo,
      storagePath: storagePath ?? this.storagePath,
      loginTimeout: loginTimeout ?? this.loginTimeout,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      dateFormat: dateFormat ?? this.dateFormat,
      pageSize: pageSize ?? this.pageSize,
      smtpServer: smtpServer ?? this.smtpServer,
      emailAccount: emailAccount ?? this.emailAccount,
      emailPassword: emailPassword ?? this.emailPassword,
    );
  }

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      settingId: json['settingId'],
      settingKey: json['settingKey'],
      settingValue: json['settingValue'],
      settingType: json['settingType'],
      category: json['category'],
      description: json['description'],
      isEncrypted: _parseBool(json['isEncrypted']),
      isEditable: _parseBool(json['isEditable']),
      sortOrder: json['sortOrder'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'],
      systemName: json['systemName'],
      systemVersion: json['systemVersion'],
      systemDescription: json['systemDescription'],
      copyrightInfo: json['copyrightInfo'],
      storagePath: json['storagePath'],
      loginTimeout: json['loginTimeout'],
      sessionTimeout: json['sessionTimeout'],
      dateFormat: json['dateFormat'],
      pageSize: json['pageSize'],
      smtpServer: json['smtpServer'],
      emailAccount: json['emailAccount'],
      emailPassword: json['emailPassword'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settingId': settingId,
      'settingKey': settingKey,
      'settingValue': settingValue,
      'settingType': settingType,
      'category': category,
      'description': description,
      'isEncrypted': isEncrypted,
      'isEditable': isEditable,
      'sortOrder': sortOrder,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'updatedAt': modifiedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'idempotencyKey': idempotencyKey,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'systemDescription': systemDescription,
      'copyrightInfo': copyrightInfo,
      'storagePath': storagePath,
      'loginTimeout': loginTimeout,
      'sessionTimeout': sessionTimeout,
      'dateFormat': dateFormat,
      'pageSize': pageSize,
      'smtpServer': smtpServer,
      'emailAccount': emailAccount,
      'emailPassword': emailPassword,
    };
  }

  @override
  String toString() {
    return 'SystemSettings(settingKey: $settingKey, settingValue: $settingValue, systemName: $systemName)';
  }

  static List<SystemSettings> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => SystemSettings.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SystemSettings> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, SystemSettings>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SystemSettings.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SystemSettings>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SystemSettings>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            SystemSettings.listFromJson(value as List<dynamic>);
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
