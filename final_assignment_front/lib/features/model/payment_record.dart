class PaymentRecordModel {
  final int? paymentId;
  final int? fineId;
  final String? paymentNumber;
  final double? paymentAmount;
  final String? paymentMethod;
  final DateTime? paymentTime;
  final String? paymentChannel;
  final String? payerName;
  final String? payerIdCard;
  final String? payerContact;
  final String? bankName;
  final String? bankAccount;
  final String? transactionId;
  final String? receiptNumber;
  final String? receiptUrl;
  final String? paymentStatus;
  final double? refundAmount;
  final DateTime? refundTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  const PaymentRecordModel({
    this.paymentId,
    this.fineId,
    this.paymentNumber,
    this.paymentAmount,
    this.paymentMethod,
    this.paymentTime,
    this.paymentChannel,
    this.payerName,
    this.payerIdCard,
    this.payerContact,
    this.bankName,
    this.bankAccount,
    this.transactionId,
    this.receiptNumber,
    this.receiptUrl,
    this.paymentStatus,
    this.refundAmount,
    this.refundTime,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.remarks,
  });

  PaymentRecordModel copyWith({
    int? paymentId,
    int? fineId,
    String? paymentNumber,
    double? paymentAmount,
    String? paymentMethod,
    DateTime? paymentTime,
    String? paymentChannel,
    String? payerName,
    String? payerIdCard,
    String? payerContact,
    String? bankName,
    String? bankAccount,
    String? transactionId,
    String? receiptNumber,
    String? receiptUrl,
    String? paymentStatus,
    double? refundAmount,
    DateTime? refundTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? remarks,
  }) {
    return PaymentRecordModel(
      paymentId: paymentId ?? this.paymentId,
      fineId: fineId ?? this.fineId,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTime: paymentTime ?? this.paymentTime,
      paymentChannel: paymentChannel ?? this.paymentChannel,
      payerName: payerName ?? this.payerName,
      payerIdCard: payerIdCard ?? this.payerIdCard,
      payerContact: payerContact ?? this.payerContact,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      transactionId: transactionId ?? this.transactionId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      refundAmount: refundAmount ?? this.refundAmount,
      refundTime: refundTime ?? this.refundTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      remarks: remarks ?? this.remarks,
    );
  }

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      paymentId: json['paymentId'],
      fineId: json['fineId'],
      paymentNumber: json['paymentNumber'],
      paymentAmount: _toDouble(json['paymentAmount']),
      paymentMethod: json['paymentMethod'],
      paymentTime: _parseDateTime(json['paymentTime']),
      paymentChannel: json['paymentChannel'],
      payerName: json['payerName'],
      payerIdCard: json['payerIdCard'],
      payerContact: json['payerContact'],
      bankName: json['bankName'],
      bankAccount: json['bankAccount'],
      transactionId: json['transactionId'],
      receiptNumber: json['receiptNumber'],
      receiptUrl: json['receiptUrl'],
      paymentStatus: json['paymentStatus'],
      refundAmount: _toDouble(json['refundAmount']),
      refundTime: _parseDateTime(json['refundTime']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: _parseDateTime(json['deletedAt']),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'fineId': fineId,
      'paymentNumber': paymentNumber,
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'paymentTime': paymentTime?.toIso8601String(),
      'paymentChannel': paymentChannel,
      'payerName': payerName,
      'payerIdCard': payerIdCard,
      'payerContact': payerContact,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'receiptUrl': receiptUrl,
      'paymentStatus': paymentStatus,
      'refundAmount': refundAmount,
      'refundTime': refundTime?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'remarks': remarks,
    };
  }

  @override
  String toString() {
    return 'PaymentRecordModel(paymentId: $paymentId, fineId: $fineId, paymentAmount: $paymentAmount, paymentStatus: $paymentStatus)';
  }

  static List<PaymentRecordModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) =>
            PaymentRecordModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Map<String, PaymentRecordModel> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, PaymentRecordModel>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = PaymentRecordModel.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<PaymentRecordModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<PaymentRecordModel>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] =
            PaymentRecordModel.listFromJson(value as List<dynamic>);
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
