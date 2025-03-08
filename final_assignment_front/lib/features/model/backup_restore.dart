class BackupRestore {
  /* 备份ID 使用自动增长类型作为主键 */
  int? backupId;

  /* 备份文件名 记录备份文件的名称 */
  String? backupFileName;

  /* 备份时间 记录执行备份操作的时间 */
  DateTime? backupTime;

  /* 恢复时间 记录执行恢复操作的时间 */
  DateTime? restoreTime;

  /* 恢复状态 描述备份文件恢复操作的状态 */
  String? restoreStatus;

  /* 备注 记录关于备份与恢复操作的额外信息 */
  String? remarks;

  String? idempotencyKey;

  BackupRestore({
    this.backupId,
    this.backupFileName,
    this.backupTime,
    this.restoreTime,
    this.restoreStatus,
    this.remarks,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'BackupRestore[backupId=$backupId, backupFileName=$backupFileName, backupTime=$backupTime, restoreTime=$restoreTime, restoreStatus=$restoreStatus, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  factory BackupRestore.fromJson(Map<String, dynamic> json) {
    return BackupRestore(
      backupId: json['backupId'] as int?,
      backupFileName: json['backupFileName'] as String?,
      backupTime: json['backupTime'] != null
          ? DateTime.parse(json['backupTime'] as String)
          : null,
      restoreTime: json['restoreTime'] != null
          ? DateTime.parse(json['restoreTime'] as String)
          : null,
      restoreStatus: json['restoreStatus'] as String?,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (backupId != null) {
      json['backupId'] = backupId;
    }
    if (backupFileName != null) {
      json['backupFileName'] = backupFileName;
    }
    if (backupTime != null) {
      json['backupTime'] = backupTime!.toIso8601String();
    }
    if (restoreTime != null) {
      json['restoreTime'] = restoreTime!.toIso8601String();
    }
    if (restoreStatus != null) {
      json['restoreStatus'] = restoreStatus;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    if (idempotencyKey != null) {
      json['idempotencyKey'] = idempotencyKey;
    }
    return json;
  }

  static List<BackupRestore> listFromJson(List<dynamic> json) {
    return json
        .map((value) => BackupRestore.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, BackupRestore> mapFromJson(Map<String, dynamic> json) {
    var map = <String, BackupRestore>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = BackupRestore.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of BackupRestore objects as value to a Dart map
  static Map<String, List<BackupRestore>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<BackupRestore>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = BackupRestore.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  // CopyWith method for creating a new instance with updated fields
  BackupRestore copyWith({
    int? backupId,
    String? backupFileName,
    DateTime? backupTime,
    DateTime? restoreTime,
    String? restoreStatus,
    String? remarks,
    String? idempotencyKey,
  }) {
    return BackupRestore(
      backupId: backupId ?? this.backupId,
      backupFileName: backupFileName ?? this.backupFileName,
      backupTime: backupTime ?? this.backupTime,
      restoreTime: restoreTime ?? this.restoreTime,
      restoreStatus: restoreStatus ?? this.restoreStatus,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}