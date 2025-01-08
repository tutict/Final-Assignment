class FineInformation {
  int? fineId;

  int? offenseId;

  /* 罚款金额 */
  num? fineAmount;

  /* 罚款时间 */
  String? fineTime;

  /* 缴费人姓名 */
  String? payee;

  /* 银行账号 */
  String? accountNumber;

  /* 银行名称 */
  String? bank;

  /* 收据编号 */
  String? receiptNumber;

  /* 备注信息 */
  String? remarks;

  String idempotencyKey;

  FineInformation({
    required int? fineId,
    required String? offenseId,
    required num? fineAmount,
    required String? fineTime,
    required String? payee,
    required String? accountNumber,
    required String? bank,
    required String? receiptNumber,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'FineInformation[fineId=$fineId, offenseId=$offenseId, fineAmount=$fineAmount, fineTime=$fineTime, payee=$payee, accountNumber=$accountNumber, bank=$bank, receiptNumber=$receiptNumber, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  FineInformation.fromJson(Map<String, dynamic> json) {
    fineId = json['fineId'];
    offenseId = json['offenseId'];
    fineAmount = json['fineAmount'];
    fineTime = json['fineTime'];
    payee = json['payee'];
    accountNumber = json['accountNumber'];
    bank = json['bank'];
    receiptNumber = json['receiptNumber'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (fineId != null) {
      json['fineId'] = fineId;
    }
    if (offenseId != null) {
      json['offenseId'] = offenseId;
    }
    if (fineAmount != null) {
      json['fineAmount'] = fineAmount;
    }
    if (fineTime != null) {
      json['fineTime'] = fineTime;
    }
    if (payee != null) {
      json['payee'] = payee;
    }
    if (accountNumber != null) {
      json['accountNumber'] = accountNumber;
    }
    if (bank != null) {
      json['bank'] = bank;
    }
    if (receiptNumber != null) {
      json['receiptNumber'] = receiptNumber;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<FineInformation> listFromJson(List<dynamic> json) {
    return json.map((value) => FineInformation.fromJson(value)).toList();
  }

  static Map<String, FineInformation> mapFromJson(Map<String, dynamic> json) {
    var map = <String, FineInformation>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = FineInformation.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of FineInformation-objects as value to a dart map
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
