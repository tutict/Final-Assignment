class FineInformation {
  final int? fineId;
  final int? offenseId;
  final String? fineNumber;
  final double? fineAmount;
  final double? lateFee;
  final double? totalAmount;
  final DateTime? fineDate;
  final DateTime? paymentDeadline;
  final String? issuingAuthority;
  final String? handler;
  final String? approver;
  final String? paymentStatus;
  final double? paidAmount;
  final double? unpaidAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  // legacy/扩展字段，兼容旧版前端仍依赖的属性
  final String? fineTime;
  final String? payee;
  final String? accountNumber;
  final String? bank;
  final String? receiptNumber;
  final String? idempotencyKey;
  final String? status;

  const FineInformation({
    this.fineId,
    this.offenseId,
    this.fineNumber,
    this.fineAmount,
    this.lateFee,
    this.totalAmount,
    this.fineDate,
    this.paymentDeadline,
    this.issuingAuthority,
    this.handler,
    this.approver,
    this.paymentStatus,
    this.paidAmount,
    this.unpaidAmount,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
    this.fineTime,
    this.payee,
    this.accountNumber,
    this.bank,
    this.receiptNumber,
    this.idempotencyKey,
    this.status,
  });

  FineInformation copyWith({
    int? fineId,
    int? offenseId,
    String? fineNumber,
    double? fineAmount,
    double? lateFee,
    double? totalAmount,
    DateTime? fineDate,
    DateTime? paymentDeadline,
    String? issuingAuthority,
    String? handler,
    String? approver,
    String? paymentStatus,
    double? paidAmount,
    double? unpaidAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
    String? fineTime,
    String? payee,
    String? accountNumber,
    String? bank,
    String? receiptNumber,
    String? idempotencyKey,
    String? status,
  }) {
    return FineInformation(
      fineId: fineId ?? this.fineId,
      offenseId: offenseId ?? this.offenseId,
      fineNumber: fineNumber ?? this.fineNumber,
      fineAmount: fineAmount ?? this.fineAmount,
      lateFee: lateFee ?? this.lateFee,
      totalAmount: totalAmount ?? this.totalAmount,
      fineDate: fineDate ?? this.fineDate,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      handler: handler ?? this.handler,
      approver: approver ?? this.approver,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      unpaidAmount: unpaidAmount ?? this.unpaidAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
      fineTime: fineTime ?? this.fineTime,
      payee: payee ?? this.payee,
      accountNumber: accountNumber ?? this.accountNumber,
      bank: bank ?? this.bank,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
    );
  }

  factory FineInformation.fromJson(Map<String, dynamic> json) {
    return FineInformation(
      fineId: json['fineId'],
      offenseId: json['offenseId'],
      fineNumber: json['fineNumber'],
      fineAmount: _toDouble(json['fineAmount']),
      lateFee: _toDouble(json['lateFee']),
      totalAmount: _toDouble(json['totalAmount']),
      fineDate: _parseDateTime(json['fineDate']),
      paymentDeadline: _parseDateTime(json['paymentDeadline']),
      issuingAuthority: json['issuingAuthority'],
      handler: json['handler'],
      approver: json['approver'],
      paymentStatus: json['paymentStatus'] ?? json['status'],
      paidAmount: _toDouble(json['paidAmount']),
      unpaidAmount: _toDouble(json['unpaidAmount']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
      fineTime: json['fineTime'] ?? json['fineDate'],
      payee: json['payee'],
      accountNumber: json['accountNumber'],
      bank: json['bank'],
      receiptNumber: json['receiptNumber'],
      idempotencyKey: json['idempotencyKey'],
      status: json['status'] ?? json['paymentStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fineId': fineId,
      'offenseId': offenseId,
      'fineNumber': fineNumber,
      'fineAmount': fineAmount,
      'lateFee': lateFee,
      'totalAmount': totalAmount,
      'fineDate': fineDate?.toIso8601String(),
      'paymentDeadline': paymentDeadline?.toIso8601String(),
      'issuingAuthority': issuingAuthority,
      'handler': handler,
      'approver': approver,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'unpaidAmount': unpaidAmount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
      'fineTime': fineTime ?? fineDate?.toIso8601String(),
      'payee': payee,
      'accountNumber': accountNumber,
      'bank': bank,
      'receiptNumber': receiptNumber,
      'idempotencyKey': idempotencyKey,
      'status': status ?? paymentStatus,
    };
  }

  static List<FineInformation> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => FineInformation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Map<String, FineInformation> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, FineInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = FineInformation.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<FineInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<FineInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = FineInformation.listFromJson(value as List<dynamic>);
      });
    }
    return map;
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
