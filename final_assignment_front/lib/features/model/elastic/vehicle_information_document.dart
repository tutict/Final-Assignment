
class VehicleInformationDocument {
  int? vehicleId;
  String? licensePlate;
  String? vehicleType;
  String? ownerName;
  String? idCardNumber;
  String? contactNumber;
  String? engineNumber;
  String? frameNumber;
  String? vehicleColor;
  String? firstRegistrationDate;
  String? currentStatus;

  VehicleInformationDocument({
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

  factory VehicleInformationDocument.fromJson(Map<String, dynamic> json) {
    return VehicleInformationDocument(
      vehicleId: json['vehicleId'] as int?,
      licensePlate: json['licensePlate'] as String?,
      vehicleType: json['vehicleType'] as String?,
      ownerName: json['ownerName'] as String?,
      idCardNumber: json['idCardNumber'] as String?,
      contactNumber: json['contactNumber'] as String?,
      engineNumber: json['engineNumber'] as String?,
      frameNumber: json['frameNumber'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      firstRegistrationDate: json['firstRegistrationDate'] as String?,
      currentStatus: json['currentStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'licensePlate': licensePlate,
      'vehicleType': vehicleType,
      'ownerName': ownerName,
      'idCardNumber': idCardNumber,
      'contactNumber': contactNumber,
      'engineNumber': engineNumber,
      'frameNumber': frameNumber,
      'vehicleColor': vehicleColor,
      'firstRegistrationDate': firstRegistrationDate,
      'currentStatus': currentStatus,
    };
  }

  static List<VehicleInformationDocument> listFromJson(List<dynamic> json) {
    return json.map((e) => VehicleInformationDocument.fromJson(e)).toList();
  }
}