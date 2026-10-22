import 'package:final_assignment_front/features/model/chat_action.dart';

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
    final payload = _payloadValue(json['payload']);
    final payloadMap = payload is Map<String, Object?> ? payload : null;
    return AiStreamEvent(
      type: AiStreamEventTypeLookup.fromWire(rawType),
      rawType: rawType,
      sessionKey: _stringValue(json['sessionKey']),
      messageId: _stringValue(json['messageId']),
      token: _stringValue(json['token']) ??
          _stringValue(payloadMap?['token']) ??
          _stringValue(payloadMap?['content']) ??
          _stringValue(payloadMap?['text']),
      payload: payload,
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

  Map<String, Object?>? get payloadMap {
    final payloadValue = payload;
    if (payloadValue is Map<String, Object?>) {
      return payloadValue;
    }
    return null;
  }

  bool get isFallback {
    final payloadValue = payloadMap;
    return payloadValue?['isFallback'] == true ||
        payloadValue?['fallback'] == true;
  }

  String? get fallbackReason =>
      payloadMap?['reason']?.toString() ??
      payloadMap?['fallback_reason']?.toString();

  String? get message {
    final payloadValue = payloadMap;
    if (payloadValue != null) {
      final value = payloadValue['message'];
      return value?.toString();
    }
    return null;
  }

  int? get queuePosition {
    final payloadValue = payloadMap;
    if (payloadValue == null) return null;
    final value = payloadValue['position'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// 后端下发的业务动作，payload 结构为 type/label/target/value。
  ChatAction? get action {
    final payloadValue = payloadMap;
    if (payloadValue == null) return null;
    final label = _stringValue(payloadValue['label']);
    final target = _stringValue(payloadValue['target']);
    if ((label == null || label.isEmpty) &&
        (target == null || target.isEmpty)) {
      return null;
    }
    return ChatAction(
      type: _stringValue(payloadValue['type']),
      label: label,
      target: target,
      value: _stringValue(payloadValue['value']),
    );
  }

  /// 工具调用名称。
  String? get toolName => _stringValue(payloadMap?['name']);

  /// 工具调用阶段，start/end。
  String? get toolPhase => _stringValue(payloadMap?['phase']);

  /// 事件携带的业务摘要。
  String? get summary => _stringValue(payloadMap?['summary']);

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
  action('action'),
  tool('tool'),
  result('result'),
  draft('draft'),
  done('done'),
  error('error'),
  usage('usage'),
  keepalive('keepalive'),
  queue('queue'),
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
