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
  String? birthdate;

  /* 首次领取驾驶证日期 */
  String? firstLicenseDate;

  /* 允许驾驶的车辆类型 */
  String? allowedVehicleType;

  /* 驾驶证发证日期 */
  String? issueDate;

  /* 驾驶证有效期截止日期 */
  String? expiryDate;

  String? idempotencyKey;

  DriverInformation({
    required int driverId,
    required String? name,
    required String? idCardNumber,
    required String? contactNumber,
    required String? driverLicenseNumber,
    required String? gender,
    required String? birthdate,
    required String? firstLicenseDate,
    required String? allowedVehicleType,
    required String? issueDate,
    required String? expiryDate,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'DriverInformation[driverId=$driverId, name=$name, idCardNumber=$idCardNumber, contactNumber=$contactNumber, driverLicenseNumber=$driverLicenseNumber, gender=$gender, birthdate=$birthdate, firstLicenseDate=$firstLicenseDate, allowedVehicleType=$allowedVehicleType, issueDate=$issueDate, expiryDate=$expiryDate, idempotencyKey=$idempotencyKey,]';
  }

  DriverInformation.fromJson(Map<String, dynamic> json) {
    driverId = json['driverId'];
    name = json['name'];
    idCardNumber = json['idCardNumber'];
    contactNumber = json['contactNumber'];
    driverLicenseNumber = json['driverLicenseNumber'];
    gender = json['gender'];
    birthdate = json['birthdate'];
    firstLicenseDate = json['firstLicenseDate'];
    allowedVehicleType = json['allowedVehicleType'];
    issueDate = json['issueDate'];
    expiryDate = json['expiryDate'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (driverId != null) {
      json['driverId'] = driverId;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (idCardNumber != null) {
      json['idCardNumber'] = idCardNumber;
    }
    if (contactNumber != null) {
      json['contactNumber'] = contactNumber;
    }
    if (driverLicenseNumber != null) {
      json['driverLicenseNumber'] = driverLicenseNumber;
    }
    if (gender != null) {
      json['gender'] = gender;
    }
    if (birthdate != null) {
      json['birthdate'] = birthdate;
    }
    if (firstLicenseDate != null) {
      json['firstLicenseDate'] = firstLicenseDate;
    }
    if (allowedVehicleType != null) {
      json['allowedVehicleType'] = allowedVehicleType;
    }
    if (issueDate != null) {
      json['issueDate'] = issueDate;
    }
    if (expiryDate != null) {
      json['expiryDate'] = expiryDate;
    }
    return json;
  }

  static List<DriverInformation> listFromJson(List<dynamic> json) {
    return json.map((value) => DriverInformation.fromJson(value)).toList();
  }

  static Map<String, DriverInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, DriverInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = DriverInformation.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of DriverInformation-objects as value to a dart map
  static Map<String, List<DriverInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<DriverInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = DriverInformation.listFromJson(value);
      });
    }
    return map;
  }
}
