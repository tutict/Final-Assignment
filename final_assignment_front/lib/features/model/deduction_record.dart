class DeductionRecordModel {
  final int? deductionId;
  final int? offenseId;
  final int? driverId;
  final int? deductedPoints;
  final DateTime? deductionTime;
  final String? scoringCycle;
  final String? handler;
  final String? handlerDept;
  final String? approver;
  final DateTime? approvalTime;
  final String? status;
  final DateTime? restoreTime;
  final String? restoreReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? remarks;
  final String? driverName;
  final String? driverLicenseNumber;
  final String? driverIdCardNumber;
  final String? licensePlate;
  final String? vehicleType;
  final String? offenseNumber;
  final String? offenseCode;
  final String? offenseType;
  final String? offenseLocation;
  final DateTime? offenseTime;

  const DeductionRecordModel({
    this.deductionId,
    this.offenseId,
    this.driverId,
    this.deductedPoints,
    this.deductionTime,
    this.scoringCycle,
    this.handler,
    this.handlerDept,
    this.approver,
    this.approvalTime,
    this.status,
    this.restoreTime,
    this.restoreReason,
    this.createdAt,
    this.updatedAt,
    this.remarks,
    this.driverName,
    this.driverLicenseNumber,
    this.driverIdCardNumber,
    this.licensePlate,
    this.vehicleType,
    this.offenseNumber,
    this.offenseCode,
    this.offenseType,
    this.offenseLocation,
    this.offenseTime,
  });

  DeductionRecordModel copyWith({
    int? deductionId,
    int? offenseId,
    int? driverId,
    int? deductedPoints,
    DateTime? deductionTime,
    String? scoringCycle,
    String? handler,
    String? handlerDept,
    String? approver,
    DateTime? approvalTime,
    String? status,
    DateTime? restoreTime,
    String? restoreReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remarks,
    String? driverName,
    String? driverLicenseNumber,
    String? driverIdCardNumber,
    String? licensePlate,
    String? vehicleType,
    String? offenseNumber,
    String? offenseCode,
    String? offenseType,
    String? offenseLocation,
    DateTime? offenseTime,
  }) {
    return DeductionRecordModel(
      deductionId: deductionId ?? this.deductionId,
      offenseId: offenseId ?? this.offenseId,
      driverId: driverId ?? this.driverId,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      deductionTime: deductionTime ?? this.deductionTime,
      scoringCycle: scoringCycle ?? this.scoringCycle,
      handler: handler ?? this.handler,
      handlerDept: handlerDept ?? this.handlerDept,
      approver: approver ?? this.approver,
      approvalTime: approvalTime ?? this.approvalTime,
      status: status ?? this.status,
      restoreTime: restoreTime ?? this.restoreTime,
      restoreReason: restoreReason ?? this.restoreReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remarks: remarks ?? this.remarks,
      driverName: driverName ?? this.driverName,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverIdCardNumber: driverIdCardNumber ?? this.driverIdCardNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      offenseNumber: offenseNumber ?? this.offenseNumber,
      offenseCode: offenseCode ?? this.offenseCode,
      offenseType: offenseType ?? this.offenseType,
      offenseLocation: offenseLocation ?? this.offenseLocation,
      offenseTime: offenseTime ?? this.offenseTime,
    );
  }

  factory DeductionRecordModel.fromJson(Map<String, dynamic> json) {
    return DeductionRecordModel(
      deductionId: json['deductionId'],
      offenseId: json['offenseId'],
      driverId: json['driverId'],
      deductedPoints: json['deductedPoints'],
      deductionTime: json['deductionTime'] != null
          ? DateTime.tryParse(json['deductionTime'])
          : null,
      scoringCycle: json['scoringCycle'],
      handler: json['handler'],
      handlerDept: json['handlerDept'],
      approver: json['approver'],
      approvalTime: json['approvalTime'] != null
          ? DateTime.tryParse(json['approvalTime'])
          : null,
      status: json['status'],
      restoreTime: json['restoreTime'] != null
          ? DateTime.tryParse(json['restoreTime'])
          : null,
      restoreReason: json['restoreReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      remarks: json['remarks'],
      driverName: json['driverName'],
      driverLicenseNumber: json['driverLicenseNumber'],
      driverIdCardNumber: json['driverIdCardNumber'],
      licensePlate: json['licensePlate'],
      vehicleType: json['vehicleType'],
      offenseNumber: json['offenseNumber'],
      offenseCode: json['offenseCode'],
      offenseType: json['offenseType'],
      offenseLocation: json['offenseLocation'],
      offenseTime: json['offenseTime'] != null
          ? DateTime.tryParse(json['offenseTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'deductionId': deductionId,
        'offenseId': offenseId,
        'driverId': driverId,
        'deductedPoints': deductedPoints,
        'deductionTime': deductionTime?.toIso8601String(),
        'scoringCycle': scoringCycle,
        'handler': handler,
        'handlerDept': handlerDept,
        'approver': approver,
        'approvalTime': approvalTime?.toIso8601String(),
        'status': status,
        'restoreTime': restoreTime?.toIso8601String(),
        'restoreReason': restoreReason,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'remarks': remarks,
        'driverName': driverName,
        'driverLicenseNumber': driverLicenseNumber,
        'driverIdCardNumber': driverIdCardNumber,
        'licensePlate': licensePlate,
        'vehicleType': vehicleType,
        'offenseNumber': offenseNumber,
        'offenseCode': offenseCode,
        'offenseType': offenseType,
        'offenseLocation': offenseLocation,
        'offenseTime': offenseTime?.toIso8601String(),
      };
}
