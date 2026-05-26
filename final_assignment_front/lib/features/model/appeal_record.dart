import 'package:final_assignment_front/utils/date_formatter.dart';

class AppealRecordModel {
  final int? appealId;
  final int? offenseId;
  final int? driverId;
  final String? appealNumber;
  final String? appellantName;
  final String? appellantIdCard;
  final String? appellantContact;
  final String? appellantEmail;
  final String? appellantAddress;
  final String? appealType;
  final String? appealReason;
  final DateTime? appealTime;
  final String? evidenceDescription;
  final String? evidenceUrls;
  final String? acceptanceStatus;
  final DateTime? acceptanceTime;
  final String? acceptanceHandler;
  final String? rejectionReason;
  final String? processStatus;
  final DateTime? processTime;
  final String? processResult;
  final String? processHandler;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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

  const AppealRecordModel({
    this.appealId,
    this.offenseId,
    this.driverId,
    this.appealNumber,
    this.appellantName,
    this.appellantIdCard,
    this.appellantContact,
    this.appellantEmail,
    this.appellantAddress,
    this.appealType,
    this.appealReason,
    this.appealTime,
    this.evidenceDescription,
    this.evidenceUrls,
    this.acceptanceStatus,
    this.acceptanceTime,
    this.acceptanceHandler,
    this.rejectionReason,
    this.processStatus,
    this.processTime,
    this.processResult,
    this.processHandler,
    this.createdAt,
    this.updatedAt,
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

  factory AppealRecordModel.fromJson(Map<String, dynamic> json) {
    return AppealRecordModel(
      appealId: json['appealId'],
      offenseId: json['offenseId'],
      driverId: json['driverId'],
      appealNumber: json['appealNumber'],
      appellantName: json['appellantName'],
      appellantIdCard: json['appellantIdCard'] ?? json['idCard'],
      appellantContact: json['appellantContact'] ?? json['contact'],
      appellantEmail: json['appellantEmail'],
      appellantAddress: json['appellantAddress'],
      appealType: json['appealType'],
      appealReason: json['appealReason'],
      appealTime: json['appealTime'] != null
          ? DateTime.tryParse(json['appealTime'])
          : null,
      evidenceDescription: json['evidenceDescription'],
      evidenceUrls: json['evidenceUrls'],
      acceptanceStatus: json['acceptanceStatus'],
      acceptanceTime: json['acceptanceTime'] != null
          ? DateTime.tryParse(json['acceptanceTime'])
          : null,
      acceptanceHandler: json['acceptanceHandler'],
      rejectionReason: json['rejectionReason'],
      processStatus: json['processStatus'],
      processTime: json['processTime'] != null
          ? DateTime.tryParse(json['processTime'])
          : null,
      processResult: json['processResult'],
      processHandler: json['processHandler'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
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
        'appealId': appealId,
        'offenseId': offenseId,
        'driverId': driverId,
        'appealNumber': appealNumber,
        'appellantName': appellantName,
        'appellantIdCard': appellantIdCard,
        'idCard': appellantIdCard,
        'appellantContact': appellantContact,
        'contact': appellantContact,
        'appellantEmail': appellantEmail,
        'appellantAddress': appellantAddress,
        'appealType': appealType,
        'appealReason': appealReason,
        'appealTime': appealTime != null
            ? DateFormatter.formatLocalDateTime(appealTime!)
            : null,
        'evidenceDescription': evidenceDescription,
        'evidenceUrls': evidenceUrls,
        'acceptanceStatus': acceptanceStatus,
        'acceptanceTime': acceptanceTime?.toIso8601String(),
        'acceptanceHandler': acceptanceHandler,
        'rejectionReason': rejectionReason,
        'processStatus': processStatus,
        'processTime': processTime?.toIso8601String(),
        'processResult': processResult,
        'processHandler': processHandler,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
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

  AppealRecordModel copyWith({
    int? appealId,
    int? offenseId,
    int? driverId,
    String? appealNumber,
    String? appellantName,
    String? appellantIdCard,
    String? appellantContact,
    String? appellantEmail,
    String? appellantAddress,
    String? appealType,
    String? appealReason,
    DateTime? appealTime,
    String? evidenceDescription,
    String? evidenceUrls,
    String? acceptanceStatus,
    DateTime? acceptanceTime,
    String? acceptanceHandler,
    String? rejectionReason,
    String? processStatus,
    DateTime? processTime,
    String? processResult,
    String? processHandler,
    DateTime? createdAt,
    DateTime? updatedAt,
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
    return AppealRecordModel(
      appealId: appealId ?? this.appealId,
      offenseId: offenseId ?? this.offenseId,
      driverId: driverId ?? this.driverId,
      appealNumber: appealNumber ?? this.appealNumber,
      appellantName: appellantName ?? this.appellantName,
      appellantIdCard: appellantIdCard ?? this.appellantIdCard,
      appellantContact: appellantContact ?? this.appellantContact,
      appellantEmail: appellantEmail ?? this.appellantEmail,
      appellantAddress: appellantAddress ?? this.appellantAddress,
      appealType: appealType ?? this.appealType,
      appealReason: appealReason ?? this.appealReason,
      appealTime: appealTime ?? this.appealTime,
      evidenceDescription: evidenceDescription ?? this.evidenceDescription,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      acceptanceStatus: acceptanceStatus ?? this.acceptanceStatus,
      acceptanceTime: acceptanceTime ?? this.acceptanceTime,
      acceptanceHandler: acceptanceHandler ?? this.acceptanceHandler,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      processStatus: processStatus ?? this.processStatus,
      processTime: processTime ?? this.processTime,
      processResult: processResult ?? this.processResult,
      processHandler: processHandler ?? this.processHandler,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
}
