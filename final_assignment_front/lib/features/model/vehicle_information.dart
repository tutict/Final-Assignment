import 'package:flutter/foundation.dart';

class VehicleInformation {
  int? vehicleId;
  String? licensePlate;
  String? vehicleType;
  String? ownerName;
  String? idCardNumber;
  String? contactNumber;
  String? engineNumber;
  String? frameNumber;
  String? vehicleColor;
  DateTime? firstRegistrationDate;
  String? currentStatus;

  VehicleInformation({
    this.vehicleId,
    this.licensePlate,
    this.vehicleType,
    this.ownerName,
    this.idCardNumber,
    this.contactNumber,
    this.engineNumber,
    this.frameNumber,
    this.vehicleColor,
    this.firstRegistrationDate,
    this.currentStatus,
  });

  @override
  String toString() {
    return 'VehicleInformation[vehicleId=$vehicleId, licensePlate=$licensePlate, vehicleType=$vehicleType, ownerName=$ownerName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, engineNumber=$engineNumber, frameNumber=$frameNumber, vehicleColor=$vehicleColor, firstRegistrationDate=$firstRegistrationDate, currentStatus=$currentStatus]';
  }

  factory VehicleInformation.fromJson(Map<String, dynamic> json) {
    return VehicleInformation(
      vehicleId: json['vehicleId'] as int?,
      licensePlate: json['licensePlate'] as String?,
      vehicleType: json['vehicleType'] as String?,
      ownerName: json['ownerName'] as String?,
      idCardNumber: json['idCardNumber'] as String?,
      contactNumber: json['contactNumber'] as String?,
      engineNumber: json['engineNumber'] as String?,
      frameNumber: json['frameNumber'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      firstRegistrationDate: json['firstRegistrationDate'] != null
          ? _parseDateTime(json['firstRegistrationDate'] as String)
          : null,
      currentStatus: json['currentStatus'] as String?,
    );
  }

  static DateTime? _parseDateTime(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('Invalid date format: $dateStr, error: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'licensePlate': licensePlate ?? '',
      'vehicleType': vehicleType ?? '',
      'ownerName': ownerName ?? '',
      'idCardNumber': idCardNumber,
      'contactNumber': contactNumber,
      'engineNumber': engineNumber,
      'frameNumber': frameNumber,
      'vehicleColor': vehicleColor,
      'firstRegistrationDate': firstRegistrationDate?.toIso8601String(),
      'currentStatus': currentStatus,
    };
  }

  VehicleInformation copyWith({
    int? vehicleId,
    String? licensePlate,
    String? vehicleType,
    String? ownerName,
    String? idCardNumber,
    String? contactNumber,
    String? engineNumber,
    String? frameNumber,
    String? vehicleColor,
    DateTime? firstRegistrationDate,
    String? currentStatus,
  }) {
    return VehicleInformation(
      vehicleId: vehicleId ?? this.vehicleId,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      ownerName: ownerName ?? this.ownerName,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      frameNumber: frameNumber ?? this.frameNumber,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      firstRegistrationDate: firstRegistrationDate ?? this.firstRegistrationDate,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  void validateForCreation() {
    if (licensePlate == null || licensePlate!.isEmpty) {
      throw Exception('车牌号不能为空');
    }
    if (vehicleType == null || vehicleType!.isEmpty) {
      throw Exception('车辆类型不能为空');
    }
    if (ownerName == null || ownerName!.isEmpty) {
      throw Exception('车主姓名不能为空');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VehicleInformation &&
              runtimeType == other.runtimeType &&
              vehicleId == other.vehicleId &&
              licensePlate == other.licensePlate &&
              vehicleType == other.vehicleType &&
              ownerName == other.ownerName &&
              idCardNumber == other.idCardNumber &&
              contactNumber == other.contactNumber &&
              engineNumber == other.engineNumber &&
              frameNumber == other.frameNumber &&
              vehicleColor == other.vehicleColor &&
              firstRegistrationDate == other.firstRegistrationDate &&
              currentStatus == other.currentStatus;

  @override
  int get hashCode => Object.hash(
    vehicleId,
    licensePlate,
    vehicleType,
    ownerName,
    idCardNumber,
    contactNumber,
    engineNumber,
    frameNumber,
    vehicleColor,
    firstRegistrationDate,
    currentStatus,
  );

  static List<VehicleInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) => VehicleInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, VehicleInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, VehicleInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = VehicleInformation.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  static Map<String, List<VehicleInformation>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<VehicleInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = VehicleInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }
}