class AppealRecordModel {
  final int? appealId;
  final int? offenseId;
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

  const AppealRecordModel({
    this.appealId,
    this.offenseId,
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
  });

  factory AppealRecordModel.fromJson(Map<String, dynamic> json) {
    return AppealRecordModel(
      appealId: json['appealId'],
      offenseId: json['offenseId'],
      appealNumber: json['appealNumber'],
      appellantName: json['appellantName'],
      appellantIdCard: json['appellantIdCard'],
      appellantContact: json['appellantContact'],
      appellantEmail: json['appellantEmail'],
      appellantAddress: json['appellantAddress'],
      appealType: json['appealType'],
      appealReason: json['appealReason'],
      appealTime:
          json['appealTime'] != null ? DateTime.tryParse(json['appealTime']) : null,
      evidenceDescription: json['evidenceDescription'],
      evidenceUrls: json['evidenceUrls'],
      acceptanceStatus: json['acceptanceStatus'],
      acceptanceTime: json['acceptanceTime'] != null
          ? DateTime.tryParse(json['acceptanceTime'])
          : null,
      acceptanceHandler: json['acceptanceHandler'],
      rejectionReason: json['rejectionReason'],
      processStatus: json['processStatus'],
      processTime:
          json['processTime'] != null ? DateTime.tryParse(json['processTime']) : null,
      processResult: json['processResult'],
      processHandler: json['processHandler'],
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'appealId': appealId,
        'offenseId': offenseId,
        'appealNumber': appealNumber,
        'appellantName': appellantName,
        'appellantIdCard': appellantIdCard,
        'appellantContact': appellantContact,
        'appellantEmail': appellantEmail,
        'appellantAddress': appellantAddress,
        'appealType': appealType,
        'appealReason': appealReason,
        'appealTime': appealTime?.toIso8601String(),
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
      };
}
