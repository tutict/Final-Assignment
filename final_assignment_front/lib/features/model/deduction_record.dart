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
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      remarks: json['remarks'],
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
      };
}
