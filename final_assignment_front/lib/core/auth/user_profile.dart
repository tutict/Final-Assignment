class UserProfile {
  const UserProfile({
    required this.authUserId,
    required this.username,
    required this.roles,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.driverId,
    this.driverName,
  });

  final int authUserId;
  final String username;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final List<String> roles;
  final int? driverId;
  final String? driverName;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      authUserId: _requiredInt(json['authUserId'] ?? json['userId']),
      username: json['username']?.toString() ?? '',
      displayName: _stringValue(json['displayName']),
      email: _stringValue(json['email']),
      phoneNumber: _stringValue(json['phoneNumber']),
      roles: _stringList(json['roles']),
      driverId: _intValue(json['driverId']),
      driverName: _stringValue(json['driverName']),
    );
  }

  factory UserProfile.fromStorage(Map<String, String?> values) {
    return UserProfile(
      authUserId: _requiredInt(
        values['auth_user_id'] ?? values['authUserId'] ?? values['userId'],
      ),
      username: values['username'] ?? values['userName'] ?? '',
      displayName: _stringValue(values['displayName']),
      email: _stringValue(values['email'] ?? values['userEmail']),
      phoneNumber: _stringValue(values['phoneNumber']),
      roles: _stringList(values['roles'] ?? values['userRole']),
      driverId: _intValue(values['driver_id'] ?? values['driverId']),
      driverName: _stringValue(values['driverName']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authUserId': authUserId,
      'username': username,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'roles': roles,
      'driverId': driverId,
      'driverName': driverName,
    };
  }

  static int _requiredInt(Object? value) {
    final parsed = _intValue(value);
    if (parsed == null) {
      throw const FormatException('authUserId is required');
    }
    return parsed;
  }

  static int? _intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return int.tryParse(text);
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty || text == 'null' ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return const [];
    if (text.startsWith('[') && text.endsWith(']')) {
      final inner = text.substring(1, text.length - 1).trim();
      if (inner.isEmpty) return const [];
      return inner
          .split(',')
          .map((item) => item.replaceAll('"', '').trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
