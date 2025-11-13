class DriverInformation {
  final int? driverId;
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

  const DriverInformation({
    this.driverId,
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
  });

  DriverInformation copyWith({
    int? driverId,
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
  }) {
    return DriverInformation(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      driverLicenseNumber:
          driverLicenseNumber ?? this.driverLicenseNumber,
      licenseType: licenseType ?? this.licenseType,
      allowedVehicleType:
          allowedVehicleType ?? this.allowedVehicleType ?? this.licenseType,
      firstLicenseDate: firstLicenseDate ?? this.firstLicenseDate,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      currentPoints: currentPoints ?? this.currentPoints,
      totalDeductedPoints:
          totalDeductedPoints ?? this.totalDeductedPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  factory DriverInformation.fromJson(Map<String, dynamic> json) {
    final type = json['licenseType'] ?? json['allowedVehicleType'];
    return DriverInformation(
      driverId: json['driverId'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'name': name,
      'idCardNumber': idCardNumber,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(),
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'driverLicenseNumber': driverLicenseNumber,
      'licenseType': licenseType ?? allowedVehicleType,
      'allowedVehicleType': allowedVehicleType ?? licenseType,
      'firstLicenseDate': firstLicenseDate?.toIso8601String(),
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
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
    };
  }

  static List<DriverInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) =>
            DriverInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, DriverInformation> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, DriverInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] =
            DriverInformation.fromJson(value as Map<String, dynamic>);
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
}
