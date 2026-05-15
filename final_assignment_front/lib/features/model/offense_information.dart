/// 违法记录数据模型。
/// 对应后端实体/DTO：com.tutict.finalassignmentbackend.entity.OffenseRecord
/// 对应 API：GET /api/offenses、POST /api/offenses
///
/// 注意：[processStatus] 和 [idempotencyKey] 由后端控制，前端只读。
// ignore_for_file: dangling_library_doc_comments

import 'package:final_assignment_front/utils/date_formatter.dart';

class OffenseInformation {
  /// 违法记录主键，用于标识本条违法记录。
  /// 与 [driverId]、[vehicleId] 是关联关系：本字段是违法记录 ID，
  /// [driverId] 指向驾驶员，[vehicleId] 指向车辆。
  /// 对应后端字段：offenseId
  final int? offenseId;
  final String? offenseCode;
  final String? offenseNumber;

  /// 违法实际发生时间。
  /// 区别于 [createdAt]：本字段是业务发生时间，[createdAt] 是记录创建时间。
  /// 对应后端字段：offenseTime
  final DateTime? offenseTime;
  final String? offenseLocation;
  final String? offenseProvince;
  final String? offenseCity;

  /// 关联驾驶员 ID，指向本次违法涉及的驾驶员。
  /// 与 [offenseId]、[vehicleId] 共同描述“哪位驾驶员驾驶哪辆车产生哪条违法记录”。
  /// 对应后端字段：driverId
  final int? driverId;

  /// 关联车辆 ID，指向本次违法涉及的车辆。
  /// 与 [offenseId]、[driverId] 共同描述“哪位驾驶员驾驶哪辆车产生哪条违法记录”。
  /// 对应后端字段：vehicleId
  final int? vehicleId;
  final String? offenseDescription;
  final String? evidenceType;
  final String? evidenceUrls;
  final String? enforcementAgency;
  final String? enforcementOfficer;
  final String? enforcementDevice;

  /// 违法记录当前处理状态。
  /// 枚举值：Unprocessed（未处理）/ Processing（处理中）/ Processed（已处理）/
  /// Appealing（申诉中）/ Appeal_Approved（申诉通过）/ Appeal_Rejected（申诉驳回）/ Cancelled（已取消）
  /// 由后端 workflow/state machine 控制，前端只读，不可在表单中直接修改。
  /// 对应后端字段：processStatus
  final String? processStatus;

  /// 通知状态，表示违法通知送达进度。
  /// 枚举值：Not_Sent（未通知）/ Sent（已发送）/ Received（已送达）/ Confirmed（已确认）
  /// 对应后端字段：notificationStatus
  /// @todo 后端当前枚举未暴露“通知失败”值，需确认失败场景是否使用额外状态。
  final String? notificationStatus;
  final DateTime? notificationTime;
  final double? fineAmount;
  final int? deductedPoints;
  final int? detentionDays;
  final DateTime? processTime;
  final String? processHandler;
  final String? processResult;

  /// 记录创建时间，由后端生成。
  /// 区别于 [offenseTime]：本字段表示记录进入系统的时间，不代表违法发生时间。
  /// 对应后端字段：createdAt
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  /// 兼容前端其他页面仍需展示的聚合字段。
  final String? licensePlate;
  final String? driverName;
  final String? offenseType;

  /// 幂等键，由后端在创建记录时自动生成。
  /// 用于防止重复提交，前端不应手动设置此字段。
  /// 对应后端字段：idempotencyKey
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
      'offenseTime': offenseTime != null
          ? DateFormatter.formatLocalDateTime(offenseTime!)
          : null,
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
        map[key] = OffenseInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<OffenseInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<OffenseInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = OffenseInformation.listFromJson(value as List<dynamic>);
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
