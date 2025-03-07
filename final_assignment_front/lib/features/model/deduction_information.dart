class DeductionInformation {
  int? deductionId;
  String? driverLicenseNumber;
  int? deductedPoints;
  DateTime? deductionTime;
  String? handler;
  String? approver;
  String? remarks;
  String? idempotencyKey; // 改为可选

  DeductionInformation({
    this.deductionId,
    this.driverLicenseNumber, // 驾驶证号
    this.deductedPoints,
    this.deductionTime,
    this.handler,
    this.approver,
    this.remarks,
    this.idempotencyKey, // 改为可选
  });

  @override
  String toString() {
    return 'DeductionInformation[deductionId=$deductionId, driverLicenseNumber=$driverLicenseNumber, deductedPoints=$deductedPoints, deductionTime=$deductionTime, handler=$handler, approver=$approver, remarks=$remarks, idempotencyKey=$idempotencyKey]';
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deductionId != null) 'deductionId': deductionId,
      if (driverLicenseNumber != null)
        'driverLicenseNumber': driverLicenseNumber,
      if (deductedPoints != null) 'deductedPoints': deductedPoints,
      if (deductionTime != null)
        'deductionTime': deductionTime!.toIso8601String(),
      if (handler != null) 'handler': handler,
      if (approver != null) 'approver': approver,
      if (remarks != null) 'remarks': remarks,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }

  static List<DeductionInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) =>
            DeductionInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, DeductionInformation> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, DeductionInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] =
          DeductionInformation.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  // Maps a JSON object with a list of DeductionInformation objects as value to a Dart map
  static Map<String, List<DeductionInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<DeductionInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DeductionInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  // CopyWith method for creating a new instance with updated fields
  DeductionInformation copyWith({
    int? deductionId,
    String? driverLicenseNumber,
    int? deductedPoints,
    DateTime? deductionTime,
    String? handler,
    String? approver,
    String? remarks,
    String? idempotencyKey,
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
    );
  }
}
