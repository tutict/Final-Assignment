class DeductionInformation {
  int? deductionId;

  /* 违纪行为ID */
  int? offenseId;

  /* 扣除分数 该字段表示因违纪行为而扣除的分数 */
  int? deductedPoints;

  /* 扣分时间 该字段记录执行扣分的具体时间 */
  String? deductionTime;

  /* 处理人 该字段记录负责处理此次扣分的人员姓名 */
  String? handler;

  /* 审批人 该字段记录对此次扣分进行审批的人员姓名 */
  String? approver;

  /* 备注 该字段用于记录关于此次扣分的额外说明或备注信息 */
  String? remarks;

  String? idempotencyKey;

  DeductionInformation({
    required String? deductionId,
    required String? offenseId,
    required String? deductedPoints,
    required String? deductionTime,
    required String? handler,
    required String? approver,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'DeductionInformation[deductionId=$deductionId, offenseId=$offenseId, deductedPoints=$deductedPoints, deductionTime=$deductionTime, handler=$handler, approver=$approver, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  DeductionInformation.fromJson(Map<String, dynamic> json) {
    deductionId = json['deductionId'];
    offenseId = json['offenseId'];
    deductedPoints = json['deductedPoints'];
    deductionTime = json['deductionTime'];
    handler = json['handler'];
    approver = json['approver'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (deductionId != null) {
      json['deductionId'] = deductionId;
    }
    if (offenseId != null) {
      json['offenseId'] = offenseId;
    }
    if (deductedPoints != null) {
      json['deductedPoints'] = deductedPoints;
    }
    if (deductionTime != null) {
      json['deductionTime'] = deductionTime;
    }
    if (handler != null) {
      json['handler'] = handler;
    }
    if (approver != null) {
      json['approver'] = approver;
    }
    json['remarks'] = remarks;
    return json;
  }

  static List<DeductionInformation> listFromJson(List<dynamic> json) {
    return json.map((value) => DeductionInformation.fromJson(value)).toList();
  }

  static Map<String, DeductionInformation> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, DeductionInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = DeductionInformation.fromJson(value));
    }
    return map;
  }

// maps a json object with a list of DeductionInformation-objects as value to a dart map
  static Map<String, List<DeductionInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<DeductionInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DeductionInformation.listFromJson(value);
      });
    }
    return map;
  }
}
