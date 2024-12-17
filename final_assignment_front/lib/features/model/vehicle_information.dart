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
  String? firstRegistrationDate;

  /* 当前状态 */
  String? currentStatus;

  VehicleInformation();

  @override
  String toString() {
    return 'VehicleInformation[vehicleId=$vehicleId, licensePlate=$licensePlate, vehicleType=$vehicleType, ownerName=$ownerName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, engineNumber=$engineNumber, frameNumber=$frameNumber, vehicleColor=$vehicleColor, firstRegistrationDate=$firstRegistrationDate, currentStatus=$currentStatus, ]';
  }

  VehicleInformation.fromJson(Map<String, dynamic> json) {
    vehicleId = json['vehicleId'];
    licensePlate = json['licensePlate'];
    vehicleType = json['vehicleType'];
    ownerName = json['ownerName'];
    idCardNumber = json['idCardNumber'];
    contactNumber = json['contactNumber'];
    engineNumber = json['engineNumber'];
    frameNumber = json['frameNumber'];
    vehicleColor = json['vehicleColor'];
    firstRegistrationDate = json['firstRegistrationDate'];
    currentStatus = json['currentStatus'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['vehicleId'] = vehicleId;
    json['licensePlate'] = licensePlate;
    json['vehicleType'] = vehicleType;
    json['ownerName'] = ownerName;
    json['idCardNumber'] = idCardNumber;
    json['contactNumber'] = contactNumber;
    json['engineNumber'] = engineNumber;
    json['frameNumber'] = frameNumber;
    json['vehicleColor'] = vehicleColor;
    json['firstRegistrationDate'] = firstRegistrationDate;
    json['currentStatus'] = currentStatus;
    return json;
  }

  static List<VehicleInformation> listFromJson(List<dynamic> json) {
    return json.map((value) => VehicleInformation.fromJson(value)).toList();
  }

  static Map<String, VehicleInformation> mapFromJson(
      Map<String, dynamic> json) {
    var map = <String, VehicleInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = VehicleInformation.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of VehicleInformation-objects as value to a dart map
  static Map<String, List<VehicleInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<VehicleInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = VehicleInformation.listFromJson(value);
      });
    }
    return map;
  }
}
