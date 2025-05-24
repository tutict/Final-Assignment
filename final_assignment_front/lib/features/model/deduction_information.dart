class DeductionInformation {
  int? deductionId;
  String? driverLicenseNumber;
  int? deductedPoints;
  DateTime? deductionTime;
  String? handler;
  String? approver;
  String? remarks;
  String? idempotencyKey;
  int? offenseId; // Added offenseId field

  DeductionInformation({
    this.deductionId,
    this.driverLicenseNumber,
    this.deductedPoints,
    this.deductionTime,
    this.handler,
    this.approver,
    this.remarks,
    this.idempotencyKey,
    this.offenseId,
  });

  @override
  String toString() {
    return 'DeductionInformation[deductionId=$deductionId, driverLicenseNumber=$driverLicenseNumber, deductedPoints=$deductedPoints, deductionTime=$deductionTime, handler=$handler, approver=$approver, remarks=$remarks, idempotencyKey=$idempotencyKey, offenseId=$offenseId]';
  }

  factory DeductionInformation.fromJson(Map<String, dynamic> json) {
    return DeductionInformation(
      deductionId: json['deductionId'] as int?,
      driverLicenseNumber: json['driverLicenseNumber'] as String?,
      deductedPoints: json['deductedPoints'] as int?,
      deductionTime: json['deductionTime'] != null
          ? DateTime.parse(json['deductionTime'] as String)
          : null,
      handler: json['handler'] as String?,
      approver: json['approver'] as String?,
      remarks: json['remarks'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
      offenseId: json['offenseId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deductionId != null) 'deductionId': deductionId,
      if (driverLicenseNumber != null) 'driverLicenseNumber': driverLicenseNumber,
      if (deductedPoints != null) 'deductedPoints': deductedPoints,
      if (deductionTime != null) 'deductionTime': deductionTime!.toIso8601String(),
      if (handler != null) 'handler': handler,
      if (approver != null) 'approver': approver,
      if (remarks != null) 'remarks': remarks,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      if (offenseId != null) 'offenseId': offenseId,
    };
  }

  static List<DeductionInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) => DeductionInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, DeductionInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, DeductionInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] =
          DeductionInformation.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  static Map<String, List<DeductionInformation>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<DeductionInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DeductionInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  DeductionInformation copyWith({
    int? deductionId,
    String? driverLicenseNumber,
    int? deductedPoints,
    DateTime? deductionTime,
    String? handler,
    String? approver,
    String? remarks,
    String? idempotencyKey,
    int? offenseId,
  }) {
    return DeductionInformation(
      deductionId: deductionId ?? this.deductionId,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      deductionTime: deductionTime ?? this.deductionTime,
      handler: handler ?? this.handler,
      approver: approver ?? this.approver,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      offenseId: offenseId ?? this.offenseId,
    );
  }
}