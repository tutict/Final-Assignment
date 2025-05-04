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

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    String status = json['status']?.toString() ?? 'Pending';
    // Validate status
    const validStatuses = ['Pending', 'Processing', 'Completed', 'Archived'];
    if (!validStatuses.contains(status)) {
      status = 'Pending'; // Default to Pending if invalid
    }
    return ProgressItem(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      status: status,
      submitTime: json['submitTime'] != null
          ? DateTime.parse(json['submitTime'] as String)
          : DateTime.now(),
      details: json['details'] as String?,
      username: json['username'] as String? ?? '',
      appealId: json['appealId'] as int?,
      deductionId: json['deductionId'] as int?,
      driverId: json['driverId'] as int?,
      fineId: json['fineId'] as int?,
      vehicleId: json['vehicleId'] as int?,
      offenseId: json['offenseId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'submitTime': submitTime.toIso8601String(),
      'details': details,
      'username': username,
      'appealId': appealId,
      'deductionId': deductionId,
      'driverId': driverId,
      'fineId': fineId,
      'vehicleId': vehicleId,
      'offenseId': offenseId,
    };
  }
}
