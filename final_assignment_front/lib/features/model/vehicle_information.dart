/// 车辆信息数据模型。
/// 对应后端实体/DTO：com.tutict.finalassignmentbackend.entity.VehicleInformation
/// 对应 API：GET /api/vehicles、POST /api/vehicles
///
/// 注意：[status] 表示车辆当前状态；[plateStatusSnapshot] 是历史快照字段，
/// 不应与当前状态混用。
// ignore_for_file: dangling_library_doc_comments

import 'package:final_assignment_front/utils/date_formatter.dart';

class VehicleInformation {
  final int? vehicleId;
  final int? driverId;
  final String? licensePlate;
  final String? plateColor;
  final String? vehicleType;
  final String? brand;
  final String? model;
  final String? vehicleColor;
  final String? engineNumber;
  final String? frameNumber;
  final String? ownerName;
  final String? ownerIdCard;
  final String? ownerContact;
  final String? ownerAddress;
  final DateTime? firstRegistrationDate;
  final DateTime? registrationDate;
  final String? issuingAuthority;

  /// 车辆当前状态。
  /// 枚举值：Active（正常）/ Inactive（停用）/ Scrapped（报废）/ Stolen（被盗）/ Mortgaged（抵押）
  /// 区别于 [plateStatusSnapshot]：本字段表示当前车辆状态。
  /// 对应后端字段：status
  final String? status;
  final DateTime? inspectionExpiryDate;
  final DateTime? insuranceExpiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  /// 车牌状态快照字段，记录违法发生时的车牌状态。
  /// 不是车辆当前状态；当前状态以 [status] 为准，避免与 [currentStatus] 混淆。
  /// 对应后端字段：currentStatus
  final String? plateStatusSnapshot;

  const VehicleInformation({
    this.vehicleId,
    this.driverId,
    this.licensePlate,
    this.plateColor,
    this.vehicleType,
    this.brand,
    this.model,
    this.vehicleColor,
    this.engineNumber,
    this.frameNumber,
    this.ownerName,
    this.ownerIdCard,
    this.ownerContact,
    this.ownerAddress,
    this.firstRegistrationDate,
    this.registrationDate,
    this.issuingAuthority,
    this.status,
    this.inspectionExpiryDate,
    this.insuranceExpiryDate,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.plateStatusSnapshot,
  });

  /// 兼容旧版字段：idCardNumber -> ownerIdCard
  String? get idCardNumber => ownerIdCard;

  /// 兼容旧版字段：contactNumber -> ownerContact
  String? get contactNumber => ownerContact;

  /// 兼容旧版字段：currentStatus -> status。
  /// 优先返回车辆当前状态 [status]；当旧接口只返回 [plateStatusSnapshot] 时作为回退。
  /// 与 [plateStatusSnapshot] 的区别：本 getter 面向 UI 读取当前状态，不表示历史快照。
  String? get currentStatus => status ?? plateStatusSnapshot;

  VehicleInformation copyWith({
    int? vehicleId,
    int? driverId,
    String? licensePlate,
    String? plateColor,
    String? vehicleType,
    String? brand,
    String? model,
    String? vehicleColor,
    String? engineNumber,
    String? frameNumber,
    String? ownerName,
    String? ownerIdCard,
    String? ownerContact,
    String? ownerAddress,
    DateTime? firstRegistrationDate,
    DateTime? registrationDate,
    String? issuingAuthority,
    String? status,
    DateTime? inspectionExpiryDate,
    DateTime? insuranceExpiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? plateStatusSnapshot,
  }) {
    return VehicleInformation(
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      licensePlate: licensePlate ?? this.licensePlate,
      plateColor: plateColor ?? this.plateColor,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      engineNumber: engineNumber ?? this.engineNumber,
      frameNumber: frameNumber ?? this.frameNumber,
      ownerName: ownerName ?? this.ownerName,
      ownerIdCard: ownerIdCard ?? this.ownerIdCard,
      ownerContact: ownerContact ?? this.ownerContact,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      firstRegistrationDate:
          firstRegistrationDate ?? this.firstRegistrationDate,
      registrationDate: registrationDate ?? this.registrationDate,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      status: status ?? this.status,
      inspectionExpiryDate: inspectionExpiryDate ?? this.inspectionExpiryDate,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      plateStatusSnapshot: plateStatusSnapshot ?? this.plateStatusSnapshot,
    );
  }

  factory VehicleInformation.fromJson(Map<String, dynamic> json) {
    return VehicleInformation(
      vehicleId: json['vehicleId'],
      driverId: json['driverId'],
      licensePlate: json['licensePlate'],
      plateColor: json['plateColor'],
      vehicleType: json['vehicleType'],
      brand: json['brand'],
      model: json['model'],
      vehicleColor: json['vehicleColor'],
      engineNumber: json['engineNumber'],
      frameNumber: json['frameNumber'],
      ownerName: json['ownerName'],
      ownerIdCard: json['ownerIdCard'] ?? json['idCardNumber'],
      ownerContact: json['ownerContact'] ?? json['contactNumber'],
      ownerAddress: json['ownerAddress'],
      firstRegistrationDate: _parseDate(json['firstRegistrationDate']),
      registrationDate: _parseDate(json['registrationDate']),
      issuingAuthority: json['issuingAuthority'],
      status: json['status'] ?? json['currentStatus'],
      inspectionExpiryDate: _parseDate(json['inspectionExpiryDate']),
      insuranceExpiryDate: _parseDate(json['insuranceExpiryDate']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      plateStatusSnapshot: json['currentStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'licensePlate': licensePlate,
      'plateColor': plateColor,
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'vehicleColor': vehicleColor,
      'engineNumber': engineNumber,
      'frameNumber': frameNumber,
      'ownerName': ownerName,
      'ownerIdCard': ownerIdCard,
      'idCardNumber': ownerIdCard,
      'ownerContact': ownerContact,
      'contactNumber': ownerContact,
      'ownerAddress': ownerAddress,
      'firstRegistrationDate': firstRegistrationDate != null
          ? DateFormatter.formatLocalDate(firstRegistrationDate!)
          : null,
      'registrationDate': registrationDate != null
          ? DateFormatter.formatLocalDate(registrationDate!)
          : null,
      'issuingAuthority': issuingAuthority,
      'status': status,
      'currentStatus': status,
      'inspectionExpiryDate': inspectionExpiryDate != null
          ? DateFormatter.formatLocalDate(inspectionExpiryDate!)
          : null,
      'insuranceExpiryDate': insuranceExpiryDate != null
          ? DateFormatter.formatLocalDate(insuranceExpiryDate!)
          : null,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
    };
  }

  static List<VehicleInformation> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) =>
            VehicleInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, VehicleInformation> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, VehicleInformation>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = VehicleInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<VehicleInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<VehicleInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = VehicleInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    return _parseDate(value);
  }
}
