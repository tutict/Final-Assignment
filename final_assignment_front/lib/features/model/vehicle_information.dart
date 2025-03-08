class VehicleInformation {
  /* 车辆 ID，主键，自动增长 */
  int? vehicleId;

  /* 车牌号 */
  String? licensePlate;

  /* 车辆类型 */
  String? vehicleType;

  /* 车主姓名 */
  String? ownerName;

  /* 身份证号码 */
  String? idCardNumber;

  /* 联系电话 */
  String? contactNumber;

  /* 发动机号 */
  String? engineNumber;

  /* 车架号 */
  String? frameNumber;

  /* 车身颜色 */
  String? vehicleColor;

  /* 首次注册日期 */
  DateTime? firstRegistrationDate;

  /* 当前状态 */
  String? currentStatus;

  String? idempotencyKey;

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
    this.idempotencyKey, // Optional, nullable
  });

  @override
  String toString() {
    return 'VehicleInformation[vehicleId=$vehicleId, licensePlate=$licensePlate, vehicleType=$vehicleType, ownerName=$ownerName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, engineNumber=$engineNumber, frameNumber=$frameNumber, vehicleColor=$vehicleColor, firstRegistrationDate=$firstRegistrationDate, currentStatus=$currentStatus, idempotencyKey=$idempotencyKey]';
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
          ? DateTime.parse(json['firstRegistrationDate'] as String)
          : null,
      currentStatus: json['currentStatus'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (vehicleId != null) json['vehicleId'] = vehicleId;
    if (licensePlate != null) json['licensePlate'] = licensePlate;
    if (vehicleType != null) json['vehicleType'] = vehicleType;
    if (ownerName != null) json['ownerName'] = ownerName;
    if (idCardNumber != null) json['idCardNumber'] = idCardNumber;
    if (contactNumber != null) json['contactNumber'] = contactNumber;
    if (engineNumber != null) json['engineNumber'] = engineNumber;
    if (frameNumber != null) json['frameNumber'] = frameNumber;
    if (vehicleColor != null) json['vehicleColor'] = vehicleColor;
    if (firstRegistrationDate != null) json['firstRegistrationDate'] = firstRegistrationDate!.toIso8601String();
    if (currentStatus != null) json['currentStatus'] = currentStatus;
    if (idempotencyKey != null) json['idempotencyKey'] = idempotencyKey;
    return json;
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
    String? idempotencyKey,
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
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

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

  // Maps a JSON object with a list of VehicleInformation objects as value to a Dart map
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