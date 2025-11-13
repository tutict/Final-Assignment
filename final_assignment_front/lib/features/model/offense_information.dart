class OffenseInformation {
  final int? offenseId;
  final String? offenseCode;
  final String? offenseNumber;
  final DateTime? offenseTime;
  final String? offenseLocation;
  final String? offenseProvince;
  final String? offenseCity;
  final int? driverId;
  final int? vehicleId;
  final String? offenseDescription;
  final String? evidenceType;
  final String? evidenceUrls;
  final String? enforcementAgency;
  final String? enforcementOfficer;
  final String? enforcementDevice;
  final String? processStatus;
  final String? notificationStatus;
  final DateTime? notificationTime;
  final double? fineAmount;
  final int? deductedPoints;
  final int? detentionDays;
  final DateTime? processTime;
  final String? processHandler;
  final String? processResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  // 兼容前端其他页面仍需展示的聚合字段
  final String? licensePlate;
  final String? driverName;
  final String? offenseType;
  final String? idempotencyKey;

  const OffenseInformation({
    this.offenseId,
    this.offenseCode,
    this.offenseNumber,
    this.offenseTime,
    this.offenseLocation,
    this.offenseProvince,
    this.offenseCity,
    this.driverId,
    this.vehicleId,
    this.offenseDescription,
    this.evidenceType,
    this.evidenceUrls,
    this.enforcementAgency,
    this.enforcementOfficer,
    this.enforcementDevice,
    this.processStatus,
    this.notificationStatus,
    this.notificationTime,
    this.fineAmount,
    this.deductedPoints,
    this.detentionDays,
    this.processTime,
    this.processHandler,
    this.processResult,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.licensePlate,
    this.driverName,
    this.offenseType,
    this.idempotencyKey,
  });

  OffenseInformation copyWith({
    int? offenseId,
    String? offenseCode,
    String? offenseNumber,
    DateTime? offenseTime,
    String? offenseLocation,
    String? offenseProvince,
    String? offenseCity,
    int? driverId,
    int? vehicleId,
    String? offenseDescription,
    String? evidenceType,
    String? evidenceUrls,
    String? enforcementAgency,
    String? enforcementOfficer,
    String? enforcementDevice,
    String? processStatus,
    String? notificationStatus,
    DateTime? notificationTime,
    double? fineAmount,
    int? deductedPoints,
    int? detentionDays,
    DateTime? processTime,
    String? processHandler,
    String? processResult,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? licensePlate,
    String? driverName,
    String? offenseType,
    String? idempotencyKey,
  }) {
    return OffenseInformation(
      offenseId: offenseId ?? this.offenseId,
      offenseCode: offenseCode ?? this.offenseCode,
      offenseNumber: offenseNumber ?? this.offenseNumber,
      offenseTime: offenseTime ?? this.offenseTime,
      offenseLocation: offenseLocation ?? this.offenseLocation,
      offenseProvince: offenseProvince ?? this.offenseProvince,
      offenseCity: offenseCity ?? this.offenseCity,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      offenseDescription: offenseDescription ?? this.offenseDescription,
      evidenceType: evidenceType ?? this.evidenceType,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      enforcementAgency: enforcementAgency ?? this.enforcementAgency,
      enforcementOfficer: enforcementOfficer ?? this.enforcementOfficer,
      enforcementDevice: enforcementDevice ?? this.enforcementDevice,
      processStatus: processStatus ?? this.processStatus,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      notificationTime: notificationTime ?? this.notificationTime,
      fineAmount: fineAmount ?? this.fineAmount,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      detentionDays: detentionDays ?? this.detentionDays,
      processTime: processTime ?? this.processTime,
      processHandler: processHandler ?? this.processHandler,
      processResult: processResult ?? this.processResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      licensePlate: licensePlate ?? this.licensePlate,
      driverName: driverName ?? this.driverName,
      offenseType: offenseType ?? this.offenseType,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory OffenseInformation.fromJson(Map<String, dynamic> json) {
    return OffenseInformation(
      offenseId: json['offenseId'],
      offenseCode: json['offenseCode'],
      offenseNumber: json['offenseNumber'],
      offenseTime: _parseDateTime(json['offenseTime']),
      offenseLocation: json['offenseLocation'],
      offenseProvince: json['offenseProvince'],
      offenseCity: json['offenseCity'],
      driverId: json['driverId'],
      vehicleId: json['vehicleId'],
      offenseDescription: json['offenseDescription'],
      evidenceType: json['evidenceType'],
      evidenceUrls: json['evidenceUrls'],
      enforcementAgency: json['enforcementAgency'],
      enforcementOfficer: json['enforcementOfficer'],
      enforcementDevice: json['enforcementDevice'],
      processStatus: json['processStatus'],
      notificationStatus: json['notificationStatus'],
      notificationTime: _parseDateTime(json['notificationTime']),
      fineAmount: _toDouble(json['fineAmount']),
      deductedPoints: json['deductedPoints'],
      detentionDays: json['detentionDays'],
      processTime: _parseDateTime(json['processTime']),
      processHandler: json['processHandler'],
      processResult: json['processResult'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      licensePlate: json['licensePlate'],
      driverName: json['driverName'],
      offenseType: json['offenseType'],
      idempotencyKey: json['idempotencyKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offenseId': offenseId,
      'offenseCode': offenseCode,
      'offenseNumber': offenseNumber,
      'offenseTime': offenseTime?.toIso8601String(),
      'offenseLocation': offenseLocation,
      'offenseProvince': offenseProvince,
      'offenseCity': offenseCity,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'offenseDescription': offenseDescription,
      'evidenceType': evidenceType,
      'evidenceUrls': evidenceUrls,
      'enforcementAgency': enforcementAgency,
      'enforcementOfficer': enforcementOfficer,
      'enforcementDevice': enforcementDevice,
      'processStatus': processStatus,
      'notificationStatus': notificationStatus,
      'notificationTime': notificationTime?.toIso8601String(),
      'fineAmount': fineAmount,
      'deductedPoints': deductedPoints,
      'detentionDays': detentionDays,
      'processTime': processTime?.toIso8601String(),
      'processHandler': processHandler,
      'processResult': processResult,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'licensePlate': licensePlate,
      'driverName': driverName,
      'offenseType': offenseType,
      'idempotencyKey': idempotencyKey,
    };
  }

  @override
  String toString() {
    return 'OffenseInformation(offenseId: $offenseId, offenseCode: $offenseCode, offenseNumber: $offenseNumber, offenseTime: $offenseTime, offenseLocation: $offenseLocation, driverId: $driverId, vehicleId: $vehicleId, fineAmount: $fineAmount, deductedPoints: $deductedPoints, processStatus: $processStatus)';
  }

  static List<OffenseInformation> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) =>
            OffenseInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, OffenseInformation> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, OffenseInformation>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            OffenseInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<OffenseInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<OffenseInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            OffenseInformation.listFromJson(value as List<dynamic>);
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

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }
}
