class BackupRestore {
  final int? backupId;
  final String? backupType;
  final String? backupFileName;
  final String? backupFilePath;
  final int? backupFileSize;
  final DateTime? backupTime;
  final int? backupDuration;
  final String? backupHandler;
  final DateTime? restoreTime;
  final int? restoreDuration;
  final String? restoreStatus;
  final String? restoreHandler;
  final String? errorMessage;
  final String? status;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;

  const BackupRestore({
    this.backupId,
    this.backupType,
    this.backupFileName,
    this.backupFilePath,
    this.backupFileSize,
    this.backupTime,
    this.backupDuration,
    this.backupHandler,
    this.restoreTime,
    this.restoreDuration,
    this.restoreStatus,
    this.restoreHandler,
    this.errorMessage,
    this.status,
    this.createdTime,
    this.modifiedTime,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
  });

  BackupRestore copyWith({
    int? backupId,
    String? backupType,
    String? backupFileName,
    String? backupFilePath,
    int? backupFileSize,
    DateTime? backupTime,
    int? backupDuration,
    String? backupHandler,
    DateTime? restoreTime,
    int? restoreDuration,
    String? restoreStatus,
    String? restoreHandler,
    String? errorMessage,
    String? status,
    DateTime? createdTime,
    DateTime? modifiedTime,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
  }) {
    return BackupRestore(
      backupId: backupId ?? this.backupId,
      backupType: backupType ?? this.backupType,
      backupFileName: backupFileName ?? this.backupFileName,
      backupFilePath: backupFilePath ?? this.backupFilePath,
      backupFileSize: backupFileSize ?? this.backupFileSize,
      backupTime: backupTime ?? this.backupTime,
      backupDuration: backupDuration ?? this.backupDuration,
      backupHandler: backupHandler ?? this.backupHandler,
      restoreTime: restoreTime ?? this.restoreTime,
      restoreDuration: restoreDuration ?? this.restoreDuration,
      restoreStatus: restoreStatus ?? this.restoreStatus,
      restoreHandler: restoreHandler ?? this.restoreHandler,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory BackupRestore.fromJson(Map<String, dynamic> json) {
    return BackupRestore(
      backupId: json['backupId'],
      backupType: json['backupType'],
      backupFileName: json['backupFileName'],
      backupFilePath: json['backupFilePath'],
      backupFileSize: json['backupFileSize'],
      backupTime: _parseDateTime(json['backupTime']),
      backupDuration: json['backupDuration'],
      backupHandler: json['backupHandler'],
      restoreTime: _parseDateTime(json['restoreTime']),
      restoreDuration: json['restoreDuration'],
      restoreStatus: json['restoreStatus'],
      restoreHandler: json['restoreHandler'],
      errorMessage: json['errorMessage'],
      status: json['status'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'backupType': backupType,
      'backupFileName': backupFileName,
      'backupFilePath': backupFilePath,
      'backupFileSize': backupFileSize,
      'backupTime': backupTime?.toIso8601String(),
      'backupDuration': backupDuration,
      'backupHandler': backupHandler,
      'restoreTime': restoreTime?.toIso8601String(),
      'restoreDuration': restoreDuration,
      'restoreStatus': restoreStatus,
      'restoreHandler': restoreHandler,
      'errorMessage': errorMessage,
      'status': status,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'updatedAt': modifiedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'idempotencyKey': idempotencyKey,
    };
  }

  @override
  String toString() {
    return 'BackupRestore(backupId: $backupId, backupType: $backupType, status: $status)';
  }

  static List<BackupRestore> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => BackupRestore.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, BackupRestore> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, BackupRestore>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = BackupRestore.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<BackupRestore>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<BackupRestore>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            BackupRestore.listFromJson(value as List<dynamic>);
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
