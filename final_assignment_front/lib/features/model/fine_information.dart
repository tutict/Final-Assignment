class FineInformation {
  int? fineId;
  int? offenseId;
  num? fineAmount;
  String? fineTime;
  String? payee;
  String? accountNumber;
  String? bank;
  String? receiptNumber;
  String? remarks;
  String idempotencyKey;

  FineInformation({
    this.fineId,
    this.offenseId,
    this.fineAmount,
    this.fineTime,
    this.payee,
    this.accountNumber,
    this.bank,
    this.receiptNumber,
    this.remarks,
    required this.idempotencyKey,
  });

  factory FineInformation.fromJson(Map<String, dynamic> json) {
    return FineInformation(
      fineId: json['fineId'],
      offenseId: json['offenseId'],
      fineAmount: json['fineAmount'],
      fineTime: json['fineTime'],
      payee: json['payee'],
      accountNumber: json['accountNumber'],
      bank: json['bank'],
      receiptNumber: json['receiptNumber'],
      remarks: json['remarks'],
      idempotencyKey: json['idempotencyKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fineId != null) 'fineId': fineId,
      if (offenseId != null) 'offenseId': offenseId,
      if (fineAmount != null) 'fineAmount': fineAmount,
      if (fineTime != null) 'fineTime': fineTime,
      if (payee != null) 'payee': payee,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (bank != null) 'bank': bank,
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (remarks != null) 'remarks': remarks,
      'idempotencyKey': idempotencyKey,
    };
  }

  static List<FineInformation> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  static Map<String, FineInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, FineInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = FineInformation.fromJson(value));
    }
    return map;
  }

  static Map<String, List<FineInformation>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<FineInformation>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = FineInformation.listFromJson(value);
      });
    }
    return map;
  }
}
