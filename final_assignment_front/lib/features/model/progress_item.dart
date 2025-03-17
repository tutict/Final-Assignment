class ProgressItem {
  final int? id;
  final String title;
  final String? status;
  final DateTime? submitTime;
  final String? details;
  final String? username;
  final int? appealId; // Link to AppealManagement
  final int? fineId; // Link to FineInformation (using receiptNumber or an ID)
  final int? vehicleId; // Link to VehicleInformation

  ProgressItem({
    this.id,
    required this.title,
    this.status,
    this.submitTime,
    this.details,
    this.username,
    this.appealId,
    this.fineId,
    this.vehicleId,
  });

  factory ProgressItem.fromJson(Map<String, dynamic> json) => ProgressItem(
        id: json['id'],
        title: json['title'],
        status: json['status'],
        submitTime: json['submitTime'] != null
            ? DateTime.parse(json['submitTime'])
            : null,
        details: json['details'],
        username: json['username'],
        appealId: json['appealId'],
        fineId: json['fineId'],
        vehicleId: json['vehicleId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'submitTime': submitTime?.toIso8601String(),
        'details': details,
        'username': username,
        'appealId': appealId,
        'fineId': fineId,
        'vehicleId': vehicleId,
      };

  ProgressItem copyWith({
    int? id,
    String? title,
    String? status,
    DateTime? submitTime,
    String? details,
    String? username,
    int? appealId,
    int? fineId,
    int? vehicleId,
  }) =>
      ProgressItem(
        id: id ?? this.id,
        title: title ?? this.title,
        status: status ?? this.status,
        submitTime: submitTime ?? this.submitTime,
        details: details ?? this.details,
        username: username ?? this.username,
        appealId: appealId ?? this.appealId,
        fineId: fineId ?? this.fineId,
        vehicleId: vehicleId ?? this.vehicleId,
      );
}
