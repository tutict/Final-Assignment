class DriverInformation {
  /* 驾驶员 ID，主键，自动生成 */
  int? driverId;

  /* 姓名 */
  String? name;

  /* 身份证号码 */
  String? idCardNumber;

  /* 联系电话 */
  String? contactNumber;

  /* 驾驶证号码 */
  String? driverLicenseNumber;

  /* 性别 */
  String? gender;

  /* 出生日期 */
  DateTime? birthdate;

  /* 首次领取驾驶证日期 */
  DateTime? firstLicenseDate;

  /* 允许驾驶的车辆类型 */
  String? allowedVehicleType;

  /* 驾驶证发证日期 */
  DateTime? issueDate;

  /* 驾驶证有效期截止日期 */
  DateTime? expiryDate;

  String? idempotencyKey; // 改为可选

  DriverInformation({
    this.driverId,
    this.name,
    this.idCardNumber,
    this.contactNumber,
    this.driverLicenseNumber,
    this.gender,
    this.birthdate,
    this.firstLicenseDate,
    this.allowedVehicleType,
    this.issueDate,
    this.expiryDate,
    this.idempotencyKey,
  });

  @override
  String toString() {
    return 'DriverInformation[driverId=$driverId, name=$name, idCardNumber=$idCardNumber, contactNumber=$contactNumber, driverLicenseNumber=$driverLicenseNumber, gender=$gender, birthdate=$birthdate, firstLicenseDate=$firstLicenseDate, allowedVehicleType=$allowedVehicleType, issueDate=$issueDate, expiryDate=$expiryDate, idempotencyKey=$idempotencyKey]';
  }

  factory DriverInformation.fromJson(Map<String, dynamic> json) {
    return DriverInformation(
      driverId: json['driverId'] as int?,
      name: _stripQuotes(json['name'] as String?),
      idCardNumber: _stripQuotes(json['idCardNumber'] as String?),
      contactNumber: _stripQuotes(json['contactNumber'] as String?),
      driverLicenseNumber: _stripQuotes(json['driverLicenseNumber'] as String?),
      gender: _stripQuotes(json['gender'] as String?),
      birthdate: json['birthdate'] != null
          ? DateTime.parse(_stripQuotes(json['birthdate'] as String?)!)
          : null,
      firstLicenseDate: json['firstLicenseDate'] != null
          ? DateTime.parse(_stripQuotes(json['firstLicenseDate'] as String?)!)
          : null,
      allowedVehicleType: _stripQuotes(json['allowedVehicleType'] as String?),
      issueDate: json['issueDate'] != null
          ? DateTime.parse(_stripQuotes(json['issueDate'] as String?)!)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(_stripQuotes(json['expiryDate'] as String?)!)
          : null,
      idempotencyKey: _stripQuotes(json['idempotencyKey'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (driverId != null) 'driverId': driverId,
      if (name != null) 'name': name,
      if (idCardNumber != null) 'idCardNumber': idCardNumber,
      if (contactNumber != null) 'contactNumber': contactNumber,
      if (driverLicenseNumber != null) 'driverLicenseNumber': driverLicenseNumber,
      if (gender != null) 'gender': gender,
      if (birthdate != null) 'birthdate': birthdate!.toIso8601String(),
      if (firstLicenseDate != null) 'firstLicenseDate': firstLicenseDate!.toIso8601String(),
      if (allowedVehicleType != null) 'allowedVehicleType': allowedVehicleType,
      if (issueDate != null) 'issueDate': issueDate!.toIso8601String(),
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }

  static List<DriverInformation> listFromJson(List<dynamic> json) {
    return json
        .map((value) => DriverInformation.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, DriverInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, DriverInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = DriverInformation.fromJson(value as Map<String, dynamic>));
    }
    return map;
  }

  static Map<String, List<DriverInformation>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<DriverInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DriverInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
  }

  // Helper to strip extra quotes from strings
  static String? _stripQuotes(String? value) {
    if (value == null) return null;
    return value.replaceAll('"', '').trim();
  }

  // CopyWith method for creating a new instance with updated fields
  DriverInformation copyWith({
    int? driverId,
    String? name,
    String? idCardNumber,
    String? contactNumber,
    String? driverLicenseNumber,
    String? gender,
    DateTime? birthdate,
    DateTime? firstLicenseDate,
    String? allowedVehicleType,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? idempotencyKey,
  }) {
    return DriverInformation(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      firstLicenseDate: firstLicenseDate ?? this.firstLicenseDate,
      allowedVehicleType: allowedVehicleType ?? this.allowedVehicleType,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}