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
  String? status; // 添加 status 字段
  String? idempotencyKey;

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
    this.status, // 初始化 status
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
      status: json['status'],
      // 解析 status
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
      if (status != null) 'status': status, // 包含 status 在 JSON 中
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
