/// 请求历史数据模型。
/// 对应后端实体/DTO：com.tutict.finalassignmentbackend.entity.SysRequestHistory
/// 对应 API：GET /api/progress、GET /api/system/logs/requests/{historyId}
///
/// 注意：[idempotencyKey] 用于幂等控制；[businessStatus] 是业务层状态，
/// 不等同于 HTTP 状态码。
class SysRequestHistoryModel {
  final int? id;

  /// 幂等键，由后端在创建记录时自动生成。
  /// 用于防止重复提交，前端不应手动设置此字段。
  /// 对应后端字段：idempotencyKey
  final String? idempotencyKey;
  final String? requestMethod;
  final String? requestUrl;

  /// 请求参数快照。
  /// 可能包含业务入参或敏感信息，前端展示、日志输出前应按后端脱敏规则处理。
  /// 对应后端字段：requestParams
  /// @todo 需后端确认该字段是否可能包含身份证号、手机号、令牌等敏感信息。
  final String? requestParams;
  final String? businessType;
  final int? businessId;

  /// 业务层处理状态。
  /// 常见值：PROCESSING（处理中）/ SUCCESS（成功）/ FAILED（失败）
  /// 区别于 HTTP 状态码：本字段描述业务幂等处理结果，不表示网络请求响应码。
  /// 对应后端字段：businessStatus
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
        map[key] =
            SysRequestHistoryModel.fromJson(value as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Map<String, List<SysRequestHistoryModel>> mapListFromJson(
      Map<String, dynamic> json) {
    final map = <String, List<SysRequestHistoryModel>>{};
    if (json.isNotEmpty) {
      json.forEach((key, value) {
        map[key] = SysRequestHistoryModel.listFromJson(value as List<dynamic>);
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
