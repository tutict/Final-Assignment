class AppealManagement {
  /* 使用@TableId标记主键字段，类型为 AUTO 自增 */
  int? appealId;

  int? offenseId;

  /* 上诉人姓名，数据库字段名为 "appellant_name" */
  String? appellantName;

  /* 身份证号码，数据库字段名为 "id_card_number" */
  String? idCardNumber;

  /* 联系电话，数据库字段名为 "contact_number" */
  String? contactNumber;

  /* 上诉原因，数据库字段名为 "appeal_reason" */
  String? appealReason;

  /* 上诉时间，使用字符串存储，数据库字段名为 "appeal_time" */
  String? appealTime;

  /* 处理状态，数据库字段名为 "process_status" */
  String? processStatus;

  /* 处理结果，数据库字段名为 "process_result" */
  String? processResult;

  /* 幂等键，记录请求的唯一标识符 */
  String idempotencyKey;

  AppealManagement({
    this.appealId,
    this.offenseId,
    this.appellantName,
    this.idCardNumber,
    this.contactNumber,
    this.appealReason,
    this.appealTime,
    this.processStatus,
    this.processResult,
    required this.idempotencyKey,
  });

  @override
  String toString() {
    return 'AppealManagement[appealId=$appealId, offenseId=$offenseId, appellantName=$appellantName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, appealReason=$appealReason, appealTime=$appealTime, processStatus=$processStatus, processResult=$processResult, idempotencyKey=$idempotencyKey]';
  }

  factory AppealManagement.fromJson(Map<String, dynamic> json) {
    return AppealManagement(
      appealId: json['appealId'],
      offenseId: json['offenseId'],
      appellantName: json['appellant_name'], // 注意字段名
      idCardNumber: json['id_card_number'],   // 注意字段名
      contactNumber: json['contact_number'],   // 注意字段名
      appealReason: json['appeal_reason'],     // 注意字段名
      appealTime: json['appeal_time'],
      processStatus: json['process_status'],   // 注意字段名
      processResult: json['process_result'],   // 注意字段名
      idempotencyKey: json['idempotencyKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (appealId != null) 'appealId': appealId,
      if (offenseId != null) 'offenseId': offenseId,
      if (appellantName != null) 'appellant_name': appellantName, // 注意字段名
      if (idCardNumber != null) 'id_card_number': idCardNumber,     // 注意字段名
      if (contactNumber != null) 'contact_number': contactNumber,   // 注意字段名
      if (appealReason != null) 'appeal_reason': appealReason,     // 注意字段名
      if (appealTime != null) 'appeal_time': appealTime,
      if (processStatus != null) 'process_status': processStatus,   // 注意字段名
      if (processResult != null) 'process_result': processResult,   // 注意字段名
      'idempotencyKey': idempotencyKey,
    };
  }

  static List<AppealManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => AppealManagement.fromJson(value)).toList();
  }

  static Map<String, AppealManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, AppealManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = AppealManagement.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of AppealManagement-objects as value to a dart map
  static Map<String, List<AppealManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<AppealManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = AppealManagement.listFromJson(value);
      });
    }
    return map;
  }
}
