import 'package:final_assignment_front/utils/json_parser.dart';

class ProgressItem {
  final int? id;
  final String title;
  final String status;
  final DateTime submitTime;
  final String? details;
  final String username;
  final int? appealId;
  final int? deductionId;
  final int? driverId;
  final int? fineId;
  final int? vehicleId;
  final int? offenseId;

  ProgressItem({
    this.id,
    required this.title,
    required this.status,
    required this.submitTime,
    this.details,
    required this.username,
    this.appealId,
    this.deductionId,
    this.driverId,
    this.fineId,
    this.vehicleId,
    this.offenseId,
  });

  ProgressItem copyWith({
    int? id,
    String? title,
    String? status,
    DateTime? submitTime,
    String? details,
    String? username,
    int? appealId,
    int? deductionId,
    int? driverId,
    int? fineId,
    int? vehicleId,
    int? offenseId,
  }) {
    return ProgressItem(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      submitTime: submitTime ?? this.submitTime,
      details: details ?? this.details,
      username: username ?? this.username,
      appealId: appealId ?? this.appealId,
      deductionId: deductionId ?? this.deductionId,
      driverId: driverId ?? this.driverId,
      fineId: fineId ?? this.fineId,
      vehicleId: vehicleId ?? this.vehicleId,
      offenseId: offenseId ?? this.offenseId,
    );
  }

  static String normalizeStatus(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    final upper = text.toUpperCase();
    if (text.isEmpty) return 'Pending';
    switch (upper) {
      case 'SUCCESS':
      case 'SUCCEEDED':
      case 'COMPLETED':
      case 'COMPLETE':
      case 'DONE':
      case 'PAID':
      case 'APPROVED':
        return 'Completed';
      case 'FAILED':
      case 'FAILURE':
      case 'ERROR':
      case 'REJECTED':
        return 'Failed';
      case 'PROCESSING':
      case 'RUNNING':
      case 'IN_PROGRESS':
        return 'Processing';
      case 'ARCHIVED':
        return 'Archived';
      case 'PENDING':
        return 'Pending';
      default:
        return text;
    }
  }

  static bool isOpenStatus(String? status) =>
      status == 'Pending' || status == 'Processing';

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    final status = normalizeStatus(json['status'] ?? json['businessStatus']);
    return ProgressItem(
      id: JsonParser.asInt(json['id']),
      title: JsonParser.asString(json['title'] ?? json['businessType']) ?? '',
      status: status,
      submitTime:
          JsonParser.asDateTime(json['submitTime'] ?? json['createdAt']) ??
              DateTime.now(),
      details: JsonParser.asString(json['details'] ?? json['requestParams']),
      username: JsonParser.asString(json['username'] ?? json['userId']) ?? '',
      appealId: JsonParser.asInt(json['appealId']),
      deductionId: JsonParser.asInt(json['deductionId']),
      driverId: JsonParser.asInt(json['driverId']),
      fineId: JsonParser.asInt(json['fineId']),
      vehicleId: JsonParser.asInt(json['vehicleId']),
      offenseId: JsonParser.asInt(json['offenseId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessType': title,
      'businessStatus': status,
      'createdAt': submitTime.toIso8601String(),
      'requestParams': details,
      'username': username,
      'title': title,
      'status': status,
      'submitTime': submitTime.toIso8601String(),
      'details': details,
      'appealId': appealId,
      'deductionId': deductionId,
      'driverId': driverId,
      'fineId': fineId,
      'vehicleId': vehicleId,
      'offenseId': offenseId,
    };
  }
}
