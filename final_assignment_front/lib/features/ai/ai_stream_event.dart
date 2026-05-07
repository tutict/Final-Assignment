class AiStreamEvent {
  AiStreamEvent({
    required this.type,
    required this.rawType,
    this.sessionKey,
    this.messageId,
    this.token,
    this.payload,
    this.timestamp,
  });

  factory AiStreamEvent.fromJson(
    Map<String, dynamic> json, {
    String? eventName,
  }) {
    final rawType = _stringValue(json['type']) ?? eventName ?? 'unknown';
    return AiStreamEvent(
      type: AiStreamEventTypeLookup.fromWire(rawType),
      rawType: rawType,
      sessionKey: _stringValue(json['sessionKey']),
      messageId: _stringValue(json['messageId']),
      token: _stringValue(json['token']),
      payload: _payloadValue(json['payload']),
      timestamp: _dateValue(json['timestamp']),
    );
  }

  factory AiStreamEvent.error(String message, {String? rawType}) {
    return AiStreamEvent(
      type: AiStreamEventType.error,
      rawType: rawType ?? AiStreamEventType.error.wireName,
      payload: {'message': message},
      timestamp: DateTime.now().toUtc(),
    );
  }

  final AiStreamEventType type;
  final String rawType;
  final String? sessionKey;
  final String? messageId;
  final String? token;
  final Object? payload;
  final DateTime? timestamp;

  String? get message {
    final payloadValue = payload;
    if (payloadValue is Map<String, Object?>) {
      final value = payloadValue['message'];
      return value?.toString();
    }
    return null;
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static Object? _payloadValue(Object? value) {
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    return value;
  }

  static DateTime? _dateValue(Object? value) {
    final text = _stringValue(value);
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

enum AiStreamEventType {
  session('session'),
  token('token'),
  done('done'),
  error('error'),
  usage('usage'),
  keepalive('keepalive'),
  unknown('unknown');

  const AiStreamEventType(this.wireName);

  final String wireName;
}

extension AiStreamEventTypeLookup on AiStreamEventType {
  static AiStreamEventType fromWire(String? value) {
    if (value == null || value.isEmpty) {
      return AiStreamEventType.unknown;
    }
    for (final type in AiStreamEventType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    return AiStreamEventType.unknown;
  }
}
