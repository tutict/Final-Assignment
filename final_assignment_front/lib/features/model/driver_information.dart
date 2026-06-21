import 'package:final_assignment_front/utils/date_formatter.dart';

class DriverInformation {
  final int? driverId;
  final int? authUserId;
  final String? name;
  final String? idCardNumber;
  final String? gender;
  final DateTime? birthdate;
  final String? contactNumber;
  final String? email;
  final String? address;
  final String? driverLicenseNumber;
  final String? licenseType;
  final String? allowedVehicleType; // 兼容旧字段
  final DateTime? firstLicenseDate;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? issuingAuthority;
  final int? currentPoints;
  final int? totalDeductedPoints;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? idempotencyKey;
  final String? username;
  final String? accountStatus;
  final int? vehicleCount;
  final int? offenseCount;
  final int? unpaidFineCount;
  final int? appealCount;

  const DriverInformation({
    this.driverId,
    this.authUserId,
    this.name,
    this.idCardNumber,
    this.gender,
    this.birthdate,
    this.contactNumber,
    this.email,
    this.address,
    this.driverLicenseNumber,
    this.licenseType,
    this.allowedVehicleType,
    this.firstLicenseDate,
    this.issueDate,
    this.expiryDate,
    this.issuingAuthority,
    this.currentPoints,
    this.totalDeductedPoints,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.idempotencyKey,
    this.username,
    this.accountStatus,
    this.vehicleCount,
    this.offenseCount,
    this.unpaidFineCount,
    this.appealCount,
  });

  DriverInformation copyWith({
    int? driverId,
    int? authUserId,
    String? name,
    String? idCardNumber,
    String? gender,
    DateTime? birthdate,
    String? contactNumber,
    String? email,
    String? address,
    String? driverLicenseNumber,
    String? licenseType,
    String? allowedVehicleType,
    DateTime? firstLicenseDate,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuingAuthority,
    int? currentPoints,
    int? totalDeductedPoints,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? idempotencyKey,
    String? username,
    String? accountStatus,
    int? vehicleCount,
    int? offenseCount,
    int? unpaidFineCount,
    int? appealCount,
  }) {
    return DriverInformation(
      driverId: driverId ?? this.driverId,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      licenseType: licenseType ?? this.licenseType,
      allowedVehicleType:
          allowedVehicleType ?? this.allowedVehicleType ?? this.licenseType,
      firstLicenseDate: firstLicenseDate ?? this.firstLicenseDate,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      currentPoints: currentPoints ?? this.currentPoints,
      totalDeductedPoints: totalDeductedPoints ?? this.totalDeductedPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      username: username ?? this.username,
      accountStatus: accountStatus ?? this.accountStatus,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      offenseCount: offenseCount ?? this.offenseCount,
      unpaidFineCount: unpaidFineCount ?? this.unpaidFineCount,
      appealCount: appealCount ?? this.appealCount,
    );
  }

  factory DriverInformation.fromJson(Map<String, dynamic> json) {
    final type = json['licenseType'] ?? json['allowedVehicleType'];
    return DriverInformation(
      driverId: json['driverId'],
      authUserId: json['authUserId'],
      name: json['name'],
      idCardNumber: _stripQuotes(json['idCardNumber']),
      gender: json['gender'],
      birthdate: _parseDate(json['birthdate']),
      contactNumber: _stripQuotes(json['contactNumber']),
      email: json['email'],
      address: json['address'],
      driverLicenseNumber: json['driverLicenseNumber'],
      licenseType: type,
      allowedVehicleType: json['allowedVehicleType'] ?? type,
      firstLicenseDate: _parseDate(json['firstLicenseDate']),
      issueDate: _parseDate(json['issueDate']),
      expiryDate: _parseDate(json['expiryDate']),
      issuingAuthority: json['issuingAuthority'],
      currentPoints: json['currentPoints'],
      totalDeductedPoints: json['totalDeductedPoints'],
      status: json['status'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'],
      username: json['username'],
      accountStatus: json['accountStatus'],
      vehicleCount: _toInt(json['vehicleCount']),
      offenseCount: _toInt(json['offenseCount']),
      unpaidFineCount: _toInt(json['unpaidFineCount']),
      appealCount: _toInt(json['appealCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'authUserId': authUserId,
      'name': name,
      'idCardNumber': idCardNumber,
      'gender': gender,
      'birthdate':
          birthdate != null ? DateFormatter.formatLocalDate(birthdate!) : null,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'driverLicenseNumber': driverLicenseNumber,
      'licenseType': licenseType ?? allowedVehicleType,
      'allowedVehicleType': allowedVehicleType ?? licenseType,
      'firstLicenseDate': firstLicenseDate != null
          ? DateFormatter.formatLocalDate(firstLicenseDate!)
          : null,
      'issueDate':
          issueDate != null ? DateFormatter.formatLocalDate(issueDate!) : null,
      'expiryDate': expiryDate != null
          ? DateFormatter.formatLocalDate(expiryDate!)
          : null,
      'issuingAuthority': issuingAuthority,
      'currentPoints': currentPoints,
      'totalDeductedPoints': totalDeductedPoints,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'idempotencyKey': idempotencyKey,
      'username': username,
      'accountStatus': accountStatus,
      'vehicleCount': vehicleCount,
      'offenseCount': offenseCount,
      'unpaidFineCount': unpaidFineCount,
      'appealCount': appealCount,
    };
  }

  static List<DriverInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) =>
            DriverInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, DriverInformation> mapFromJson(Map<String, dynamic> json) {
    final map = <String, DriverInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DriverInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<DriverInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<DriverInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DriverInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  static String? _stripQuotes(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.replaceAll('"', '').trim();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) => _parseDate(value);

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }
}
