class AppealManagement {
  /* 申诉ID（主键，自增） */
  int? appealId;

  /* 违法记录ID（关联字段） */
  int? offenseId;

  /* 上诉人姓名，对应数据库字段 "appellant_name" */
  String? appellantName;

  /* 身份证号码，对应数据库字段 "id_card_number" */
  String? idCardNumber;

  /* 联系电话，对应数据库字段 "contact_number" */
  String? contactNumber;

  /* 上诉原因，对应数据库字段 "appeal_reason" */
  String? appealReason;

  /* 上诉时间，对应数据库字段 "appeal_time" */
  DateTime? appealTime;

  /* 处理状态，对应数据库字段 "process_status" */
  String? processStatus;

  /* 处理结果，对应数据库字段 "process_result" */
  String? processResult;

  /* 幂等键，记录请求的唯一标识符 */
  String? idempotencyKey;

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
    this.idempotencyKey,
  });

  // Add copyWith method
  AppealManagement copyWith({
    int? appealId,
    int? offenseId,
    String? appellantName,
    String? idCardNumber,
    String? contactNumber,
    String? appealReason,
    DateTime? appealTime,
    String? processStatus,
    String? processResult,
    String? idempotencyKey,
  }) {
    return AppealManagement(
      appealId: appealId ?? this.appealId,
      offenseId: offenseId ?? this.offenseId,
      appellantName: appellantName ?? this.appellantName,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      appealReason: appealReason ?? this.appealReason,
      appealTime: appealTime ?? this.appealTime,
      processStatus: processStatus ?? this.processStatus,
      processResult: processResult ?? this.processResult,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return 'AppealManagement[appealId=$appealId, offenseId=$offenseId, appellantName=$appellantName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, appealReason=$appealReason, appealTime=$appealTime, processStatus=$processStatus, processResult=$processResult, idempotencyKey=$idempotencyKey]';
  }

  AppealManagement.fromJson(Map<String, dynamic> json) {
    appealId = json['appealId'];
    offenseId = json['offenseId'];
    appellantName = json['appellant_name'];
    idCardNumber = json['id_card_number'];
    contactNumber = json['contact_number'];
    appealReason = json['appeal_reason'];
    appealTime = json['appeal_time'] != null ? DateTime.parse(json['appeal_time']) : null;
    processStatus = json['process_status'];
    processResult = json['process_result'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (appealId != null) 'appealId': appealId,
      if (offenseId != null) 'offenseId': offenseId,
      if (appellantName != null) 'appellant_name': appellantName,
      if (idCardNumber != null) 'id_card_number': idCardNumber,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (appealReason != null) 'appeal_reason': appealReason,
      if (appealTime != null) 'appeal_time': appealTime!.toIso8601String(),
      if (processStatus != null) 'process_status': processStatus,
      if (processResult != null) 'process_result': processResult,
      'idempotencyKey': idempotencyKey,
    };
  }

  static List<AppealManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => AppealManagement.fromJson(value)).toList();
  }

  static Map<String, AppealManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, AppealManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = AppealManagement.fromJson(value);
      });
    }
    return map;
  }

  static Map<String, List<AppealManagement>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<AppealManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = listFromJson(value);
      });
    }
    return map;
  }
}