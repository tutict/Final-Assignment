class SysRequestHistoryModel {
  final int? id;
  final String? idempotencyKey;
  final String? requestMethod;
  final String? requestUrl;
  final String? requestParams;
  final String? businessType;
  final int? businessId;
  final String? businessStatus;
  final int? userId;
  final String? requestIp;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final DateTime? deletedAt;

  const SysRequestHistoryModel({
    this.id,
    this.idempotencyKey,
    this.requestMethod,
    this.requestUrl,
    this.requestParams,
    this.businessType,
    this.businessId,
    this.businessStatus,
    this.userId,
    this.requestIp,
    this.createdTime,
    this.modifiedTime,
    this.deletedAt,
  });

  SysRequestHistoryModel copyWith({
    int? id,
    String? idempotencyKey,
    String? requestMethod,
    String? requestUrl,
    String? requestParams,
    String? businessType,
    int? businessId,
    String? businessStatus,
    int? userId,
    String? requestIp,
    DateTime? createdTime,
    DateTime? modifiedTime,
    DateTime? deletedAt,
  }) {
    return SysRequestHistoryModel(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      requestMethod: requestMethod ?? this.requestMethod,
      requestUrl: requestUrl ?? this.requestUrl,
      requestParams: requestParams ?? this.requestParams,
      businessType: businessType ?? this.businessType,
      businessId: businessId ?? this.businessId,
      businessStatus: businessStatus ?? this.businessStatus,
      userId: userId ?? this.userId,
      requestIp: requestIp ?? this.requestIp,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory SysRequestHistoryModel.fromJson(Map<String, dynamic> json) {
    return SysRequestHistoryModel(
      id: json['id'],
      idempotencyKey: json['idempotencyKey'],
      requestMethod: json['requestMethod'],
      requestUrl: json['requestUrl'],
      requestParams: json['requestParams'],
      businessType: json['businessType'],
      businessId: json['businessId'],
      businessStatus: json['businessStatus'],
      userId: json['userId'],
      requestIp: json['requestIp'],
      createdTime: _parseDateTime(json['createdAt'] ?? json['createdTime']),
      modifiedTime: _parseDateTime(json['updatedAt'] ?? json['modifiedTime']),
      deletedAt: _parseDateTime(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idempotencyKey': idempotencyKey,
      'requestMethod': requestMethod,
      'requestUrl': requestUrl,
      'requestParams': requestParams,
      'businessType': businessType,
      'businessId': businessId,
      'businessStatus': businessStatus,
      'userId': userId,
      'requestIp': requestIp,
      'createdAt': createdTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'updatedAt': modifiedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static List<SysRequestHistoryModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((value) =>
            SysRequestHistoryModel.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Map<String, SysRequestHistoryModel> mapFromJson(
      Map<String, dynamic> json) {
    final map = <String, SysRequestHistoryModel>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = SysRequestHistoryModel.fromJson(
            value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SysRequestHistoryModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SysRequestHistoryModel>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = SysRequestHistoryModel.listFromJson(
            value as List<dynamic>);
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
}
