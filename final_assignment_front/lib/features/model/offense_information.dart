class OffenseInformation {
  /* 违规ID，自动增长 */
  int? offenseId;

  /* 违规时间 */
  String? offenseTime;

  /* 违规地点 */
  String? offenseLocation;

  /* 车牌号 */
  String? licensePlate;

  /* 司机姓名 */
  String? driverName;

  /* 违规类型 */
  String? offenseType;

  /* 违规代码 */
  String? offenseCode;

  /* 罚款金额 */
  num? fineAmount;

  /* 扣分 */
  int? deductedPoints;

  /* 处理状态 */
  String? processStatus;

  /* 处理结果 */
  String? processResult;

  String idempotencyKey;

  OffenseInformation({
    required int? offenseId,
    required String? offenseTime,
    required String? offenseLocation,
    required String? licensePlate,
    required String? driverName,
    required String? offenseType,
    required String? offenseCode,
    required num? fineAmount,
    required int? deductedPoints,
    required String? processStatus,
    required String? processResult,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'OffenseInformation[offenseId=$offenseId, offenseTime=$offenseTime, offenseLocation=$offenseLocation, licensePlate=$licensePlate, driverName=$driverName, offenseType=$offenseType, offenseCode=$offenseCode, fineAmount=$fineAmount, deductedPoints=$deductedPoints, processStatus=$processStatus, processResult=$processResult, idempotencyKey=$idempotencyKey, ]';
  }

  OffenseInformation.fromJson(Map<String, dynamic> json) {
    offenseId = json['offenseId'];
    offenseTime = json['offenseTime'];
    offenseLocation = json['offenseLocation'];
    licensePlate = json['licensePlate'];
    driverName = json['driverName'];
    offenseType = json['offenseType'];
    offenseCode = json['offenseCode'];
    fineAmount = json['fineAmount'];
    deductedPoints = json['deductedPoints'];
    processStatus = json['processStatus'];
    processResult = json['processResult'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (offenseId != null) {
      json['offenseId'] = offenseId;
    }
    if (offenseTime != null) {
      json['offenseTime'] = offenseTime;
    }
    if (offenseLocation != null) {
      json['offenseLocation'] = offenseLocation;
    }
    if (licensePlate != null) {
      json['licensePlate'] = licensePlate;
    }
    if (driverName != null) {
      json['driverName'] = driverName;
    }
    if (offenseType != null) {
      json['offenseType'] = offenseType;
    }
    if (offenseCode != null) {
      json['offenseCode'] = offenseCode;
    }
    if (fineAmount != null) {
      json['fineAmount'] = fineAmount;
    }
    if (deductedPoints != null) {
      json['deductedPoints'] = deductedPoints;
    }
    if (processStatus != null) {
      json['processStatus'] = processStatus;
    }
    if (processResult != null) {
      json['processResult'] = processResult;
    }
    return json;
  }

  static List<OffenseInformation> listFromJson(List<dynamic> json) {
    return json.map((value) => OffenseInformation.fromJson(value)).toList();
  }

  static Map<String, OffenseInformation> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, OffenseInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = OffenseInformation.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of OffenseInformation-objects as value to a dart map
  static Map<String, List<OffenseInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<OffenseInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = OffenseInformation.listFromJson(value);
      });
    }
    return map;
  }
}
