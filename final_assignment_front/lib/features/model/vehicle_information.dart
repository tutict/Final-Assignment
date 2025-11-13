class VehicleInformation {
  final int? vehicleId;
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
  final String? status;
  final DateTime? inspectionExpiryDate;
  final DateTime? insuranceExpiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;
  final String? plateStatusSnapshot; // legacy UI fields fallback

  const VehicleInformation({
    this.vehicleId,
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

  /// 兼容旧版字段：currentStatus -> status
  String? get currentStatus => status ?? plateStatusSnapshot;

  VehicleInformation copyWith({
    int? vehicleId,
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
      inspectionExpiryDate:
          inspectionExpiryDate ?? this.inspectionExpiryDate,
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
      firstRegistrationDate:
          _parseDate(json['firstRegistrationDate']),
      registrationDate: _parseDate(json['registrationDate']),
      issuingAuthority: json['issuingAuthority'],
      status: json['status'] ?? json['currentStatus'],
      inspectionExpiryDate:
          _parseDate(json['inspectionExpiryDate']),
      insuranceExpiryDate:
          _parseDate(json['insuranceExpiryDate']),
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
      'firstRegistrationDate':
          firstRegistrationDate?.toIso8601String(),
      'registrationDate': registrationDate?.toIso8601String(),
      'issuingAuthority': issuingAuthority,
      'status': status,
      'currentStatus': status,
      'inspectionExpiryDate':
          inspectionExpiryDate?.toIso8601String(),
      'insuranceExpiryDate':
          insuranceExpiryDate?.toIso8601String(),
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
        map[key] =
            VehicleInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<VehicleInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<VehicleInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] =
            VehicleInformation.listFromJson(value as List<dynamic>);
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
