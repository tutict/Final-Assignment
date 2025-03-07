class OffenseInformation {
  int? offenseId; // 违规ID，自动增长
  String? offenseTime; // 违规时间
  String? offenseLocation; // 违规地点
  String? licensePlate; // 车牌号
  String? driverName; // 司机姓名
  String? offenseType; // 违规类型
  String? offenseCode; // 违规代码
  num? fineAmount; // 罚款金额
  int? deductedPoints; // 扣分
  String? processStatus; // 处理状态
  String? processResult; // 处理结果
  String? idempotencyKey; // 幂等键，可选但通常需要提供

  OffenseInformation({
    this.offenseId,
    this.offenseTime,
    this.offenseLocation,
    this.licensePlate,
    this.driverName,
    this.offenseType,
    this.offenseCode,
    this.fineAmount,
    this.deductedPoints,
    this.processStatus,
    this.processResult,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'OffenseInformation[offenseId=$offenseId, offenseTime=$offenseTime, offenseLocation=$offenseLocation, licensePlate=$licensePlate, driverName=$driverName, offenseType=$offenseType, offenseCode=$offenseCode, fineAmount=$fineAmount, deductedPoints=$deductedPoints, processStatus=$processStatus, processResult=$processResult, idempotencyKey=$idempotencyKey]';
  }

  factory OffenseInformation.fromJson(Map<String, dynamic> json) {
    return OffenseInformation(
      offenseId: json['offenseId'] as int?,
      offenseTime: json['offenseTime'] as String?,
      offenseLocation: json['offenseLocation'] as String?,
      licensePlate: json['licensePlate'] as String?,
      driverName: json['driverName'] as String?,
      offenseType: json['offenseType'] as String?,
      offenseCode: json['offenseCode'] as String?,
      fineAmount: json['fineAmount'] as num?,
      deductedPoints: json['deductedPoints'] as int?,
      processStatus: json['processStatus'] as String?,
      processResult: json['processResult'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (offenseId != null) json['offenseId'] = offenseId;
    if (offenseTime != null) json['offenseTime'] = offenseTime;
    if (offenseLocation != null) json['offenseLocation'] = offenseLocation;
    if (licensePlate != null) json['licensePlate'] = licensePlate;
    if (driverName != null) json['driverName'] = driverName;
    if (offenseType != null) json['offenseType'] = offenseType;
    if (offenseCode != null) json['offenseCode'] = offenseCode;
    if (fineAmount != null) json['fineAmount'] = fineAmount;
    if (deductedPoints != null) json['deductedPoints'] = deductedPoints;
    if (processStatus != null) json['processStatus'] = processStatus;
    if (processResult != null) json['processResult'] = processResult;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
  }

  OffenseInformation copyWith({
    int? offenseId,
    String? offenseTime,
    String? offenseLocation,
    String? licensePlate,
    String? driverName,
    String? offenseType,
    String? offenseCode,
    num? fineAmount,
    int? deductedPoints,
    String? processStatus,
    String? processResult,
    String? idempotencyKey,
  }) {
    return OffenseInformation(
      offenseId: offenseId ?? this.offenseId,
      offenseTime: offenseTime ?? this.offenseTime,
      offenseLocation: offenseLocation ?? this.offenseLocation,
      licensePlate: licensePlate ?? this.licensePlate,
      driverName: driverName ?? this.driverName,
      offenseType: offenseType ?? this.offenseType,
      offenseCode: offenseCode ?? this.offenseCode,
      fineAmount: fineAmount ?? this.fineAmount,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      processStatus: processStatus ?? this.processStatus,
      processResult: processResult ?? this.processResult,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  static List<OffenseInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) => OffenseInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, OffenseInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, OffenseInformation>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) =>
      map[key] = OffenseInformation.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  static Map<String, List<OffenseInformation>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<OffenseInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = OffenseInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}