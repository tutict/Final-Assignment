class OffenseTypeDictModel {
  final int? typeId;
  final String? offenseCode;
  final String? offenseName;
  final String? category;
  final String? description;
  final double? standardFineAmount;
  final double? minFineAmount;
  final double? maxFineAmount;
  final int? deductedPoints;
  final int? detentionDays;
  final int? licenseSuspensionDays;
  final String? severityLevel;
  final String? legalBasis;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? remarks;

  const OffenseTypeDictModel({
    this.typeId,
    this.offenseCode,
    this.offenseName,
    this.category,
    this.description,
    this.standardFineAmount,
    this.minFineAmount,
    this.maxFineAmount,
    this.deductedPoints,
    this.detentionDays,
    this.licenseSuspensionDays,
    this.severityLevel,
    this.legalBasis,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.remarks,
  });

  OffenseTypeDictModel copyWith({
    int? typeId,
    String? offenseCode,
    String? offenseName,
    String? category,
    String? description,
    double? standardFineAmount,
    double? minFineAmount,
    double? maxFineAmount,
    int? deductedPoints,
    int? detentionDays,
    int? licenseSuspensionDays,
    String? severityLevel,
    String? legalBasis,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? remarks,
  }) {
    return OffenseTypeDictModel(
      typeId: typeId ?? this.typeId,
      offenseCode: offenseCode ?? this.offenseCode,
      offenseName: offenseName ?? this.offenseName,
      category: category ?? this.category,
      description: description ?? this.description,
      standardFineAmount: standardFineAmount ?? this.standardFineAmount,
      minFineAmount: minFineAmount ?? this.minFineAmount,
      maxFineAmount: maxFineAmount ?? this.maxFineAmount,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      detentionDays: detentionDays ?? this.detentionDays,
      licenseSuspensionDays:
          licenseSuspensionDays ?? this.licenseSuspensionDays,
      severityLevel: severityLevel ?? this.severityLevel,
      legalBasis: legalBasis ?? this.legalBasis,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  factory OffenseTypeDictModel.fromJson(Map<String, dynamic> json) {
    return OffenseTypeDictModel(
      typeId: json['typeId'],
      offenseCode: json['offenseCode'],
      offenseName: json['offenseName'],
      category: json['category'],
      description: json['description'],
      standardFineAmount: _toDouble(json['standardFineAmount']),
      minFineAmount: _toDouble(json['minFineAmount']),
      maxFineAmount: _toDouble(json['maxFineAmount']),
      deductedPoints: json['deductedPoints'],
      detentionDays: json['detentionDays'],
      licenseSuspensionDays: json['licenseSuspensionDays'],
      severityLevel: json['severityLevel'],
      legalBasis: json['legalBasis'],
      status: json['status'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeId': typeId,
      'offenseCode': offenseCode,
      'offenseName': offenseName,
      'category': category,
      'description': description,
      'standardFineAmount': standardFineAmount,
      'minFineAmount': minFineAmount,
      'maxFineAmount': maxFineAmount,
      'deductedPoints': deductedPoints,
      'detentionDays': detentionDays,
      'licenseSuspensionDays': licenseSuspensionDays,
      'severityLevel': severityLevel,
      'legalBasis': legalBasis,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
    };
  }

  static List<OffenseTypeDictModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) => OffenseTypeDictModel.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }
}
