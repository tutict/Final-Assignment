/// 罚款记录数据模型。
/// 对应后端实体/DTO：com.tutict.finalassignmentbackend.entity.FineRecord
/// 对应 API：GET /api/fines、POST /api/fines
///
/// 注意：[paymentStatus] 表示支付进度，[status] 表示罚单本身状态；
/// [idempotencyKey] 由后端控制，前端只读。
class FineInformation {
  final int? fineId;
  final int? offenseId;
  final int? driverId;
  final String? fineNumber;

  /// 基础罚款金额。
  /// 通常与 [lateFee] 一起参与 [totalAmount] 的计算，最终金额以后端返回为准。
  /// 对应后端字段：fineAmount
  final double? fineAmount;

  /// 滞纳金金额。
  /// 通常计入 [totalAmount]；是否产生滞纳金由后端根据缴款期限计算。
  /// 对应后端字段：lateFee
  final double? lateFee;

  /// 应缴总金额。
  /// 通常为 [fineAmount] 与 [lateFee] 计算后的结果；如存在减免，以后端结果为准。
  /// 对应后端字段：totalAmount
  final double? totalAmount;
  final DateTime? fineDate;
  final DateTime? paymentDeadline;
  final String? issuingAuthority;
  final String? handler;
  final String? approver;

  /// 支付状态，表示罚款缴纳进度。
  /// 枚举值：Unpaid（未支付）/ Partial（部分支付）/ Paid（已支付）/ Overdue（逾期）/ Waived（减免）
  /// 区别于 [status]：本字段只描述支付进度，不表示罚单记录是否有效或作废。
  /// 对应后端字段：paymentStatus
  final String? paymentStatus;

  /// 已支付金额。
  /// 通常用于和 [totalAmount] 一起计算 [unpaidAmount]，最终金额以后端返回为准。
  /// 对应后端字段：paidAmount
  final double? paidAmount;

  /// 未支付金额。
  /// 通常为 [totalAmount] 扣除 [paidAmount] 后的结果，最终金额以后端返回为准。
  /// 对应后端字段：unpaidAmount
  final double? unpaidAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? remarks;

  /// legacy/扩展字段，兼容旧版前端仍依赖的属性。
  final String? fineTime;
  final String? payee;
  final String? accountNumber;
  final String? bank;
  final String? receiptNumber;

  /// 幂等键，由后端在创建记录时自动生成。
  /// 用于防止重复提交，前端不应手动设置此字段。
  /// 对应后端字段：idempotencyKey
  final String? idempotencyKey;

  /// 罚单状态，表示罚单记录是否有效、作废或减免。
  /// 区别于 [paymentStatus]：本字段描述罚单本身状态，不表示支付进度。
  /// 对应后端字段：status
  /// @todo 后端 FineRecord 当前未显式声明 status 字段，需确认枚举值与来源。
  final String? status;

  const FineInformation({
    this.fineId,
    this.offenseId,
    this.driverId,
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
    int? driverId,
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
      driverId: driverId ?? this.driverId,
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
      driverId: json['driverId'],
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
      'driverId': driverId,
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

  static Map<String, FineInformation> mapFromJson(Map<String, dynamic> json) {
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
