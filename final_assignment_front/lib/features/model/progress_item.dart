// progress_item.dart
class ProgressItem {
  final int id;
  final String title;
  final String status; // "Pending", "Processing", "Completed", "Archived"
  final DateTime? submitTime; // ISO 8601 格式（如 "2023-10-01T12:00:00Z"）
  final String? details;
  final String? username;

  ProgressItem({
    required this.id,
    required this.title,
    required this.status,
    this.submitTime, // Changed to optional
    this.details,
    this.username,
  });

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    return ProgressItem(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      submitTime: json['submitTime'] != null
          ? DateTime.parse(json['submitTime'] as String)
          : null,
      details: json['details'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      if (submitTime != null) 'submitTime': submitTime!.toIso8601String(),
      if (details != null) 'details': details,
      if (username != null) 'username': username,
    };
  }

  // 添加 copyWith 方法
  ProgressItem copyWith({
    int? id,
    String? title,
    String? status,
    DateTime? submitTime,
    String? details,
    String? username,
  }) {
    return ProgressItem(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      submitTime: submitTime ?? this.submitTime,
      details: details ?? this.details,
      username: username ?? this.username,
    );
  }
}
