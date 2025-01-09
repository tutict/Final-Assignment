class BackupRestore {
  /* 备份ID 使用自动增长类型作为主键 */
  int? backupId;

  /* 备份文件名 记录备份文件的名称 */
  String? backupFileName;

  /* 备份时间 记录执行备份操作的时间 */
  String? backupTime;

  /* 恢复时间 记录执行恢复操作的时间 */
  String? restoreTime;

  /* 恢复状态 描述备份文件恢复操作的状态 */
  String? restoreStatus;

  /* 备注 记录关于备份与恢复操作的额外信息 */
  String? remarks;

  String? idempotencyKey;

  BackupRestore(
     {required int? backupId,
      required String? backupFileName,
      required String? backupTime,
      required String? restoreTime,
      required String? restoreStatus,
      required String? remarks,
      required String idempotencyKey });

  @override
  String toString() {
    return 'BackupRestore[backupId=$backupId, backupFileName=$backupFileName, backupTime=$backupTime, restoreTime=$restoreTime, restoreStatus=$restoreStatus, remarks=$remarks, idempotencyKey=$idempotencyKey]';
  }

  BackupRestore.fromJson(Map<String, dynamic> json) {
    backupId = json['backupId'];
    backupFileName = json['backupFileName'];
    backupTime = json['backupTime'];
    restoreTime = json['restoreTime'];
    restoreStatus = json['restoreStatus'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (backupId != null) {
      json['backupId'] = backupId;
    }
    if (backupFileName != null) {
      json['backupFileName'] = backupFileName;
    }
    if (backupTime != null) {
      json['backupTime'] = backupTime;
    }
    if (restoreTime != null) {
      json['restoreTime'] = restoreTime;
    }
    if (restoreStatus != null) {
      json['restoreStatus'] = restoreStatus;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<BackupRestore> listFromJson(List<dynamic> json) {
    return json.map((value) => BackupRestore.fromJson(value)).toList();
  }

  static Map<String, BackupRestore> mapFromJson(Map<String, dynamic> json) {
    var map = <String, BackupRestore>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = BackupRestore.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of BackupRestore-objects as value to a dart map
  static Map<String, List<BackupRestore>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<BackupRestore>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = BackupRestore.listFromJson(value);
      });
    }
    return map;
  }
}
